import 'package:flutter/material.dart';

import 'data/store.dart';
import 'screens/decorate/decorate_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/my/my_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/record/record_screen.dart';
import 'screens/report/report_screen.dart';
import 'theme.dart';
import 'widgets/ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore()..load();
  runApp(SogsalApp(store: store));
}

class SogsalApp extends StatelessWidget {
  final AppStore store;
  const SogsalApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) => StoreScope(
        store: store,
        child: MaterialApp(
          title: '속살',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: const _Root(),
        ),
      );
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    if (!store.loaded) {
      return const Scaffold(body: Paper(child: SizedBox.expand()));
    }
    return store.onboarded ? const _Tabs() : const OnboardingScreen();
  }
}

class _Tabs extends StatefulWidget {
  const _Tabs();

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    RecordScreen(),
    ReportScreen(),
    DecorateScreen(),
    MyScreen(),
  ];

  static const _tabs = [
    (Icons.accessibility_new, '홈'),
    (Icons.edit_outlined, '기록'),
    (Icons.show_chart, '리포트'),
    (Icons.palette_outlined, '꾸미기'),
    (Icons.person_outline, '마이'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: Riso.sheet,
            border: Border(top: BorderSide(color: Riso.ink, width: 1.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == _index,
                        label: _tabs[i].$2,
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: () => setState(() => _index = i),
                          child: Column(
                            children: [
                              // 선택된 탭: 위쪽 굵은 먹선
                              Container(
                                height: 3,
                                margin: const EdgeInsets.symmetric(horizontal: 18),
                                color: i == _index ? Riso.ink : Colors.transparent,
                              ),
                              const Spacer(),
                              Icon(_tabs[i].$1,
                                  size: 22, color: i == _index ? Riso.ink : Riso.faint),
                              const SizedBox(height: 2),
                              Text(
                                _tabs[i].$2,
                                style: TextStyle(
                                  fontFamily: Txt.body,
                                  fontSize: 12,
                                  fontWeight: i == _index ? FontWeight.w600 : FontWeight.w400,
                                  color: i == _index ? Riso.ink : Riso.sub,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
