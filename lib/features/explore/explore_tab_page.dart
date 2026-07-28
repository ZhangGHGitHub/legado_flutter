import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book_source.dart';
import '../../providers/source_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/source_chip.dart';
import '../search/search_page.dart';
import 'explore_list_page.dart';
import 'explore_utils.dart';

/// 发现 Tab — 对齐 ExploreFragment
class ExploreTabPage extends StatefulWidget {
  const ExploreTabPage({super.key});

  @override
  State<ExploreTabPage> createState() => ExploreTabPageState();
}

class ExploreTabPageState extends State<ExploreTabPage> {
  int _selectedSourceIndex = 0;
  bool _compressed = false;

  /// 双击发现 Tab 折叠/展开（F2 MainShell 调用）
  void compressExplore() {
    setState(() => _compressed = !_compressed);
  }

  List<BookSource> _exploreSources(SourceProvider provider) =>
      provider.sources.where(sourceHasExplore).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '联合搜索',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
          ),
        ],
      ),
      body: Consumer<SourceProvider>(
        builder: (context, provider, _) {
          final sources = _exploreSources(provider);
          if (sources.isEmpty) {
            return const EmptyState(
              icon: Icons.explore_outlined,
              title: '暂无发现书源',
              subtitle: '请在「我的 → 书源管理」中启用含发现规则的书源',
            );
          }

          if (_selectedSourceIndex >= sources.length) {
            _selectedSourceIndex = 0;
          }
          final current = sources[_selectedSourceIndex];
          final categories = parseExploreCategories(exploreUrlOf(current));
          final sections = groupExploreSections(categories);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  itemCount: sources.length,
                  itemBuilder: (_, i) => SourceChip(
                    label: sources[i].bookSourceName,
                    selected: i == _selectedSourceIndex,
                    onTap: () => setState(() => _selectedSourceIndex = i),
                  ),
                ),
              ),
              const Divider(height: 1),
              if (sections.isEmpty)
                const Expanded(
                  child: EmptyState(
                    icon: Icons.category_outlined,
                    title: '无法解析发现分类',
                    subtitle: '该书源 exploreUrl 格式暂不支持，请先使用 7565 笔书网测试',
                  ),
                )
              else if (_compressed)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: sections
                        .map(
                          (s) => ListTile(
                            title: Text(s.title.isEmpty ? '分类' : s.title),
                            subtitle: Text('${s.categories.length} 项'),
                            trailing: const Icon(Icons.expand_more),
                            onTap: () => setState(() => _compressed = false),
                          ),
                        )
                        .toList(),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: sections.length,
                    itemBuilder: (_, si) {
                      final section = sections[si];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (section.title.isNotEmpty)
                            SectionHeader(section.title),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 2.4,
                                ),
                            itemCount: section.categories.length,
                            itemBuilder: (_, ci) {
                              final cat = section.categories[ci];
                              return Material(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExploreListPage(
                                        source: current,
                                        exploreUrl: cat.url,
                                        title: cat.title,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cat.title,
                                      style: const TextStyle(fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
