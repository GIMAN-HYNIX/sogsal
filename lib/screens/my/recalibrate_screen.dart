// 체성분 기록(재보정). 인바디 실측을 넣으면 추정값을 대체한다.
import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../theme.dart';
import '../../widgets/body_comp_form.dart';
import '../../widgets/ui.dart';

class RecalibrateScreen extends StatelessWidget {
  const RecalibrateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = store.profile!;
    return Scaffold(
      body: Paper(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                        offset: const Offset(-12, 0),
                        child: IconButton(
                          tooltip: '뒤로',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Riso.ink),
                        ),
                      ),
                    ),
                  ),
                  const Text('체성분 기록', style: Txt.h2),
                  const SizedBox(height: 24),
                  BodyCompForm(
                    gender: p.gender,
                    heightCm: p.heightCm,
                    age: p.age,
                    initialWeightKg: store.latest?.weightKg,
                    submitLabel: '기록하기',
                    onSubmit: (b) {
                      store.addRecord(b);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('체성분을 기록했어요.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
