import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_router.dart';
import '../../auth/presentation/auth_view_model.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  // API 연결 전 화면 배치 확인용 임시 데이터입니다.
  static const _templates = [
    (category: 'Spring Boot', title: 'JWT 기반 사용자 인증 시스템 구현', likes: 128),
    (category: 'Spring Security', title: '이메일 인증 회원가입 시스템', likes: 96),
    (category: 'Database', title: '효율적인 ERD 설계 가이드', likes: 74),
  ];
  static const _missions = [
    (
      title: '사용자 로그인 기능 구현',
      detail: 'JWT 로그인 시스템 구현하기',
      success: true,
      date: '2025.08.24',
    ),
    (
      title: '게시글 작성 기능 구현',
      detail: '마크다운 지원 첨부 기능 포함',
      success: false,
      date: '2025.08.20',
    ),
    (
      title: '비밀번호 찾기 기능 구현',
      detail: '이메일 인증 기반 비밀번호 재설정',
      success: true,
      date: '2025.08.18',
    ),
    (
      title: '파일 업로드 및 다운로드 API 구현',
      detail: 'S3 연동 파일 관리 API',
      success: true,
      date: '2025.08.15',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: '홈으로 돌아가기',
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(AppRouteNames.home);
                }
              },
            ),
            title: Text(
              '마이페이지',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              const IconButton(
                onPressed: null,
                tooltip: '알림',
                icon: Icon(Icons.notifications_outlined),
              ),
              IconButton(
                tooltip: '계정 관리',
                onPressed: () => DefaultTabController.of(context).animateTo(3),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              labelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'MY홈'),
                Tab(text: '내 학습'),
                Tab(text: '대시보드'),
                Tab(text: '계정 관리'),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: TabBarView(
              children: [
                _myHome(context),
                _learning(context),
                _dashboard(context),
                _account(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _myHome(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      key: const PageStorageKey('my-home'),
      padding: const EdgeInsets.all(24),
      children: [
        _profile(context),
        const SizedBox(height: 24),
        _section(
          context,
          '활동 요약',
          trailing: Text('오늘 기준', style: text.labelSmall),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _activity(
                    context,
                    Icons.favorite_border,
                    '5',
                    '좋아요한 템플릿',
                  ),
                ),
                const VerticalDivider(width: 16),
                Expanded(
                  child: _activity(
                    context,
                    Icons.assignment_outlined,
                    '12',
                    '수행한 미션',
                  ),
                ),
                const VerticalDivider(width: 16),
                Expanded(
                  child: _activity(
                    context,
                    Icons.check_circle_outline,
                    '7',
                    '성공한 미션',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _section(
          context,
          '좋아요한 템플릿',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _templates.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _template(context, i)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _section(
          context,
          '최근 미션 수행 기록',
          child: Column(
            children: [
              for (var i = 0; i < _missions.length; i++) ...[
                if (i > 0) const Divider(height: 24),
                _mission(context, i),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _learning(BuildContext context) => ListView(
    key: const PageStorageKey('my-learning'),
    padding: const EdgeInsets.all(24),
    children: [
      _pageTitle(context, '내 학습', '학습 중인 과정과 진행 상황을 확인하세요.'),
      _section(
        context,
        '학습 현황',
        trailing: const Text('예시'),
        child: Row(
          children: [
            Expanded(
              child: _activity(context, Icons.menu_book_outlined, '2', '전체 학습'),
            ),
            Expanded(child: _activity(context, Icons.trending_up, '2', '학습 중')),
            Expanded(
              child: _activity(context, Icons.check_circle_outline, '0', '완료'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _section(
        context,
        '전체 학습 시간',
        trailing: const SizedBox.shrink(),
        child: Text(
          '1시간 7분',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 16),
      _learningCard(context, '자바의 정석', '1. 자바란?', .93),
      const SizedBox(height: 12),
      _learningCard(context, '파이썬 기초 마스터', '0. 파이썬이란?', .5),
    ],
  );

  Widget _learningCard(
    BuildContext context,
    String title,
    String chapter,
    double progress,
  ) => _section(
    context,
    title,
    trailing: _badge(context, '학습 중'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(chapter, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: LinearProgressIndicator(value: progress)),
            const SizedBox(width: 12),
            Text('${(progress * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 12),
        const OutlinedButton(onPressed: null, child: Text('이어서 학습')),
      ],
    ),
  );

  Widget _dashboard(BuildContext context) => ListView(
    key: const PageStorageKey('my-dashboard'),
    padding: const EdgeInsets.all(24),
    children: [
      _pageTitle(context, '대시보드', '나의 학습과 미션 활동을 한눈에 확인하세요.'),
      _section(
        context,
        '미션 현황',
        trailing: const Text('예시'),
        child: Row(
          children: [
            Expanded(
              child: _activity(
                context,
                Icons.assignment_outlined,
                '12',
                '수행한 미션',
              ),
            ),
            Expanded(
              child: _activity(
                context,
                Icons.check_circle_outline,
                '7',
                '성공한 미션',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _section(
        context,
        '최근 활동',
        trailing: const SizedBox.shrink(),
        child: Column(
          children: [
            _mission(context, 0),
            const Divider(height: 24),
            _mission(context, 1),
          ],
        ),
      ),
    ],
  );

  Widget _account(BuildContext context) => ListView(
    key: const PageStorageKey('my-account'),
    padding: const EdgeInsets.all(24),
    children: [
      _pageTitle(context, '계정 관리', '프로필과 계정 정보를 관리하세요.'),
      _section(
        context,
        '내 정보',
        trailing: const SizedBox.shrink(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '닉네임: ${context.watch<AuthViewModel>().user?.nickname ?? "-"}',
            ),
            const SizedBox(height: 12),
            Text('이메일: ${context.watch<AuthViewModel>().user?.email ?? "-"}'),
            const SizedBox(height: 12),
            const Text('가입일: 서버 정보 미제공'),
            const SizedBox(height: 16),
            Text(
              '로그인한 계정 정보입니다. 프로필 변경 기능은 추후 연결됩니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Card(
        child: Column(
          children: [
            ListTile(
              enabled: false,
              leading: Icon(Icons.person_outline),
              title: Text('프로필 수정'),
              trailing: Icon(Icons.chevron_right),
            ),
            Divider(height: 1),
            ListTile(
              enabled: false,
              leading: Icon(Icons.lock_outline),
              title: Text('비밀번호 변경'),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: context.watch<AuthViewModel>().isBusy
            ? null
            : () => context.read<AuthViewModel>().logout(),
        child: const Text('로그아웃'),
      ),
    ],
  );

  Widget _pageTitle(BuildContext context, String title, String description) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      );
  Widget _profile(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.person, size: 56, color: colors.primary),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: colors.primary,
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 16,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    context.watch<AuthViewModel>().user?.nickname ?? '-',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _badge(
                    context,
                    context.watch<AuthViewModel>().user?.role == 'ADMIN'
                        ? '관리자'
                        : '학습자',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '✉ ${context.watch<AuthViewModel>().user?.email ?? "-"}',
                style: text.bodySmall,
              ),
              const SizedBox(height: 4),
              Text('가입일 정보 미제공', style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    String title, {
    Widget? trailing,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing ??
                    Text(
                      '전체 보기 ›',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _activity(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _template(BuildContext context, int index) {
    final item = _templates[index];
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.category,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.favorite, size: 16, color: theme.colorScheme.primary),
              Text('${item.likes}', style: theme.textTheme.labelSmall),
              const Icon(Icons.bookmark_border, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mission(BuildContext context, int index) {
    final item = _missions[index];
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.assignment_outlined,
          size: 24,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(item.detail, style: theme.textTheme.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _badge(
                    context,
                    item.success ? '성공' : '실패',
                    isError: !item.success,
                  ),
                  Text(item.date, style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 20),
      ],
    );
  }

  Widget _badge(BuildContext context, String label, {bool isError = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isError
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isError
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
