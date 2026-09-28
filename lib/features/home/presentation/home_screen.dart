import 'package:flutter/material.dart';

enum HomeContentState { loading, empty, loaded, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialContentState = HomeContentState.loaded,
  });

  final HomeContentState initialContentState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeContentState _contentState;

  @override
  void initState() {
    super.initState();
    _contentState = widget.initialContentState;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _retry() async {
    setState(() => _contentState = HomeContentState.loading);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _contentState = HomeContentState.loaded);
  }

  void _showChat() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COBIP 챗봇',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('챗봇 기능은 담당 화면 연결 후 이용할 수 있습니다.'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COBIP',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  tooltip: '프로필',
                  onPressed: () =>
                      _showMessage('마이페이지는 담당 화면 연결 후 이용할 수 있습니다.'),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              '오늘도 한 단계 성장해 볼까요?',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('최근 학습을 이어서 진행하고 새로운 학습을 만나보세요.'),
            const SizedBox(height: 24),
            _buildContent(context),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 3) {
            _showChat();
          } else if (index != 0) {
            _showMessage('해당 화면은 담당 팀과 연결 후 이용할 수 있습니다.');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: '학습',
          ),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), label: '문제'),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            label: '챗봇',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (_contentState) {
      HomeContentState.loading => _loadingContent(context),
      HomeContentState.empty => _emptyContent(context),
      HomeContentState.loaded => _loadedContent(context),
      HomeContentState.error => _errorContent(context),
    };
  }

  Widget _loadingContent(BuildContext context) {
    final placeholderColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, '마지막 학습 바로가기'),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: placeholderColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(context, '학습 추천'),
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: placeholderColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _emptyContent(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 시작한 학습이 없어요',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('첫 학습을 시작하고 성장 기록을 만들어 보세요.'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => _showMessage('학습 화면은 담당 팀과 연결 후 이용할 수 있습니다.'),
              child: const Text('학습 시작하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, '마지막 학습 바로가기'),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showMessage('학습 상세 화면은 담당 팀과 연결 후 이용할 수 있습니다.'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('학습 중'),
                  const SizedBox(height: 8),
                  Text(
                    '파이썬 기초',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('4장. 자료구조 및 알고리즘'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: LinearProgressIndicator(value: .7)),
                      const SizedBox(width: 12),
                      Text(
                        '70%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(context, '학습 추천'),
        _recommendationCard(context, '데이터베이스', 'SQL 기본 원리'),
        _recommendationCard(context, '프로그래밍', '알고리즘 기초'),
      ],
    );
  }

  Widget _errorContent(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              '학습 정보를 불러오지 못했어요',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('연결을 확인하고 다시 시도해 주세요.'),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: _retry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _recommendationCard(
    BuildContext context,
    String category,
    String title,
  ) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(category),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => _showMessage('학습 상세 화면은 담당 팀과 연결 후 이용할 수 있습니다.'),
      ),
    );
  }
}
