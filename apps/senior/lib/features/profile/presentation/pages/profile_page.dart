import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// 내 정보 — UI만 존재한다. `profile` feature는 아직 domain/data 계층도,
/// 저장할 서버 테이블(`users`)도 없어서 실제로는 아무것도 저장되지 않는다.
/// 화면 자체를 만들지 않는 대신, 입력 UX를 미리 검증할 수 있게 폼은 보여주되
/// "저장" 시 명확히 안내한다 — 저장되는 것처럼 조용히 넘어가지 않는다.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _regionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('프로필 저장 기능은 아직 준비 중이에요.')));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '내 정보',
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: '이름', controller: _nameController),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: '나이',
            controller: _ageController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: '지역', controller: _regionController),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(label: '저장', onPressed: _save),
        ],
      ),
    );
  }
}
