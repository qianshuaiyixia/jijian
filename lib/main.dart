import 'package:flutter/material.dart';

/// 极简日记 —— Phase 0 骨架
/// 目标：先把 CI 链路打通，此刻只验证「能装到 iPhone 上」，不含业务功能。
void main() {
  runApp(const JiJianApp());
}

class JiJianApp extends StatelessWidget {
  const JiJianApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF8B6B4A); // 檀木褐，后期用于信纸/强调色
    return MaterialApp(
      title: '极简日记',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFFBF8F1),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system, // Phase 2 起改为可手动切换
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('极简日记')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 56,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                '还没有日记',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点右下角的按钮，写下第一篇',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // Phase 1 实现：打开编辑页
        tooltip: '写日记',
        child: const Icon(Icons.edit),
      ),
    );
  }
}
