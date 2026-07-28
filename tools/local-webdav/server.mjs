import { createHash } from "node:crypto";
import { createServer } from "node:http";
import { createReadStream } from "node:fs";
import {
  mkdir,
  readdir,
  rename,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { basename, dirname, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const port = Number.parseInt(process.env.LOCAL_WEBDAV_PORT || "19080", 10);
const host = process.env.LOCAL_WEBDAV_HOST || "0.0.0.0";
const username = process.env.LOCAL_WEBDAV_USER || "legado";
const password = process.env.LOCAL_WEBDAV_PASSWORD || "legado-test";
const root = resolve(
  process.env.LOCAL_WEBDAV_ROOT ||
    resolve(dirname(fileURLToPath(import.meta.url)), "../../.local-webdav/data"),
);

await mkdir(root, { recursive: true });

const server = createServer(async (request, response) => {
  try {
    if (!isAuthorized(request)) {
      response.writeHead(401, { "WWW-Authenticate": 'Basic realm="legado-local-webdav"' });
      response.end("Authentication required");
      return;
    }

    const target = resolveTarget(request.url);
    switch (request.method) {
      case "OPTIONS":
        send(response, 200, "", davHeaders());
        return;
      case "PROPFIND":
        await handlePropfind(request, response, target);
        return;
      case "MKCOL":
        await handleMkcol(response, target);
        return;
      case "PUT":
        await handlePut(request, response, target);
        return;
      case "GET":
      case "HEAD":
        await handleGet(request, response, target);
        return;
      case "DELETE":
        await handleDelete(response, target);
        return;
      case "MOVE":
        await handleMove(request, response, target);
        return;
      default:
        send(response, 405, "Method not allowed", {
          ...davHeaders(),
          Allow: "OPTIONS, PROPFIND, MKCOL, PUT, GET, HEAD, DELETE, MOVE",
        });
    }
  } catch (error) {
    if (error.code === "ENOENT") {
      send(response, 404, "Not found", davHeaders());
      return;
    }
    if (error.statusCode) {
      send(response, error.statusCode, error.message, davHeaders());
      return;
    }
    console.error(error);
    send(response, 500, "Internal server error", davHeaders());
  }
});

server.listen(port, host, () => {
  console.log(`Local WebDAV listening at http://${host}:${port}/`);
  console.log(`Data root: ${root}`);
});

function isAuthorized(request) {
  if (!username && !password) {
    return true;
  }
  const expected = `Basic ${Buffer.from(`${username}:${password}`).toString("base64")}`;
  return request.headers.authorization === expected;
}

function davHeaders(extra = {}) {
  return {
    DAV: "1, 2",
    "MS-Author-Via": "DAV",
    ...extra,
  };
}

function resolveTarget(rawUrl) {
  const url = new URL(rawUrl || "/", "http://localhost");
  const parts = url.pathname
    .split("/")
    .filter(Boolean)
    .map((part) => decodeURIComponent(part));

  if (parts.some((part) => part === "." || part === ".." || part.includes("/") || part.includes("\\"))) {
    const error = new Error("Invalid path");
    error.statusCode = 400;
    throw error;
  }

  const target = resolve(root, ...parts);
  const rootWithSep = root.endsWith(sep) ? root : `${root}${sep}`;
  const lowerTarget = target.toLowerCase();
  if (lowerTarget !== root.toLowerCase() && !lowerTarget.startsWith(rootWithSep.toLowerCase())) {
    const error = new Error("Invalid path");
    error.statusCode = 400;
    throw error;
  }
  return target;
}

async function handlePropfind(request, response, target) {
  const targetStat = await stat(target);
  const depth = request.headers.depth || "infinity";
  const entries = [{ path: target, stats: targetStat }];

  if (targetStat.isDirectory() && depth !== "0") {
    const children = await readdir(target);
    for (const child of children) {
      const childPath = resolve(target, child);
      entries.push({ path: childPath, stats: await stat(childPath) });
    }
  }

  const body = `<?xml version="1.0" encoding="utf-8"?>\n` +
    `<d:multistatus xmlns:d="DAV:">\n` +
    entries.map(({ path, stats }) => responseXml(path, stats)).join("") +
    `</d:multistatus>\n`;

  send(response, 207, body, {
    ...davHeaders(),
    "Content-Type": "application/xml; charset=utf-8",
  });
}

async function handleMkcol(response, target) {
  try {
    await stat(target);
    send(response, 405, "Collection already exists", davHeaders());
    return;
  } catch (error) {
    if (error.code !== "ENOENT") {
      throw error;
    }
  }
  await mkdir(target, { recursive: true });
  send(response, 201, "", davHeaders());
}

async function handlePut(request, response, target) {
  const existing = await stat(target).catch((error) => {
    if (error.code === "ENOENT") {
      return null;
    }
    throw error;
  });

  const ifMatch = request.headers["if-match"];
  if (ifMatch && !matchesIfMatch(ifMatch, target, existing)) {
    send(response, 412, "Precondition failed", davHeaders());
    return;
  }

  await mkdir(dirname(target), { recursive: true });
  const data = await readBody(request);
  await writeFile(target, data);
  const written = await stat(target);
  send(response, existing ? 204 : 201, "", {
    ...davHeaders(),
    ETag: makeEtag(target, written),
  });
}

async function handleGet(request, response, target) {
  const stats = await stat(target);
  if (stats.isDirectory()) {
    const names = await readdir(target);
    send(response, 200, names.join("\n"), {
      ...davHeaders(),
      "Content-Type": "text/plain; charset=utf-8",
    });
    return;
  }

  response.writeHead(200, {
    ...davHeaders(),
    "Content-Length": stats.size,
    "Last-Modified": stats.mtime.toUTCString(),
    ETag: makeEtag(target, stats),
  });
  if (request.method === "HEAD") {
    response.end();
    return;
  }
  createReadStream(target).pipe(response);
}

async function handleDelete(response, target) {
  await rm(target, { recursive: true, force: false });
  send(response, 204, "", davHeaders());
}

async function handleMove(request, response, target) {
  await stat(target);
  const destination = request.headers.destination;
  if (!destination) {
    send(response, 400, "Missing Destination header", davHeaders());
    return;
  }

  const destinationTarget = resolveTarget(new URL(destination, "http://localhost").pathname);
  const overwrite = (request.headers.overwrite || "T").toUpperCase();
  const destinationExists = await stat(destinationTarget).then(() => true).catch((error) => {
    if (error.code === "ENOENT") {
      return false;
    }
    throw error;
  });

  if (destinationExists && overwrite === "F") {
    send(response, 412, "Destination exists", davHeaders());
    return;
  }

  if (destinationExists) {
    await rm(destinationTarget, { recursive: true, force: true });
  }
  await mkdir(dirname(destinationTarget), { recursive: true });
  await rename(target, destinationTarget);
  send(response, destinationExists ? 204 : 201, "", davHeaders());
}

function matchesIfMatch(header, path, existing) {
  if (!existing) {
    return false;
  }
  if (header.trim() === "*") {
    return true;
  }
  const tags = header.split(",").map((tag) => tag.trim());
  return tags.includes(makeEtag(path, existing));
}

function responseXml(path, stats) {
  const isDir = stats.isDirectory();
  const href = hrefFor(path, isDir);
  const resourceType = isDir ? "<d:collection/>" : "";
  const size = isDir ? 0 : stats.size;

  return `  <d:response>\n` +
    `    <d:href>${escapeXml(href)}</d:href>\n` +
    `    <d:propstat>\n` +
    `      <d:prop>\n` +
    `        <d:displayname>${escapeXml(displayName(path))}</d:displayname>\n` +
    `        <d:getcontentlength>${size}</d:getcontentlength>\n` +
    `        <d:getlastmodified>${stats.mtime.toUTCString()}</d:getlastmodified>\n` +
    `        <d:getetag>${escapeXml(makeEtag(path, stats))}</d:getetag>\n` +
    `        <d:resourcetype>${resourceType}</d:resourcetype>\n` +
    `      </d:prop>\n` +
    `      <d:status>HTTP/1.1 200 OK</d:status>\n` +
    `    </d:propstat>\n` +
    `  </d:response>\n`;
}

function hrefFor(path, isDir) {
  const rel = relative(root, path).split(sep).filter(Boolean);
  const href = `/${rel.map(encodeURIComponent).join("/")}`;
  return isDir && !href.endsWith("/") ? `${href}/` : href || "/";
}

function displayName(path) {
  return path === root ? "" : basename(path);
}

function makeEtag(path, stats) {
  const hash = createHash("sha1")
    .update(`${path}:${stats.size}:${Math.floor(stats.mtimeMs)}`)
    .digest("hex")
    .slice(0, 16);
  return `"${hash}"`;
}

function escapeXml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

function readBody(request) {
  return new Promise((resolveBody, rejectBody) => {
    const chunks = [];
    request.on("data", (chunk) => chunks.push(chunk));
    request.on("end", () => resolveBody(Buffer.concat(chunks)));
    request.on("error", rejectBody);
  });
}

function send(response, statusCode, body, headers = {}) {
  const payload = Buffer.from(body || "");
  response.writeHead(statusCode, {
    "Content-Length": payload.length,
    ...headers,
  });
  response.end(payload);
}
