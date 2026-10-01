import 'package:flutter/material.dart';
import '../data/courses.dart';
import '../data/outfits.dart';
import '../game_state.dart';
import 'collection_screen.dart';
import 'wardrobe_screen.dart';
import '../widgets/walk_record_card.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 내 정보 탭: 완주한 나라, 콜렉션 진행률(누르면 도감), 오늘 기록, 달력
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.game});
  final GameState game;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month); // 달력에 보이는 달
  DateTime? _selected; // 달력에서 고른 날

  GameState get game => widget.game;

  void _openCollection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Collection')),
          body: CollectionScreen(game: game),
        ),
      ),
    );
  }

  /// 연필 버튼: 이름 바꾸기 창
  Future<void> _editName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initial: game.playerName),
    );
    if (name != null) game.setPlayerName(name);
  }

  void _openWardrobe() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WardrobeScreen(game: game)),
    );
  }

  /// 콜렉션 · 옷장으로 들어가는 메뉴 카드
  Widget _menuCard({
    required String title,
    required String trailing,
    required Widget body,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Text(trailing,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: game,
        builder: (context, _) {
          final total = game.collectionTotal;
          final pct = total == 0 ? 0.0 : game.collectionOwned / total;
          final completed = [
            for (final c in kCourses)
              if (game.timesCompleted(c) > 0) c,
          ];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 프로필 머리: 캐릭터 이미지 + 이름(연필 버튼으로 수정)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // 캐릭터 이미지 자리 (와이어프레임)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: const SizedBox(width: 140, height: 140, child: Placeholder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 40), // 연필 버튼만큼 왼쪽을 띄워 이름을 가운데로
                        Flexible(
                          child: Text(game.playerName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Edit name',
                          onPressed: _editName,
                        ),
                      ],
                    ),
                    Text('Wearing ${game.outfit.name}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text('Total CO₂ saved ${game.totalCo2Kg.toStringAsFixed(2)} kg',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 완주한 나라
              _title('Completed countries'),
              if (completed.isEmpty)
                const Text('No countries completed yet. Keep walking!',
                    style: TextStyle(color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in completed)
                      Chip(
                        avatar: const Icon(Icons.flag, size: 16),
                        label: Text(game.timesCompleted(c) > 1
                            ? '${c.country} ×${game.timesCompleted(c)}'
                            : c.country),
                      ),
                  ],
                ),
              const SizedBox(height: 24),

              // 콜렉션 진행률. 누르면 도감 화면으로 이동
              _menuCard(
                title: 'Collection',
                trailing: '${(pct * 100).toStringAsFixed(0)}%',
                onTap: _openCollection,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: pct),
                    const SizedBox(height: 4),
                    Text('${game.collectionOwned} / $total items collected',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 옷장. 누르면 옷 갈아입기 화면으로 이동
              _menuCard(
                title: 'Wardrobe',
                trailing: '${kOutfits.where(game.ownsOutfit).length} / ${kOutfits.length}',
                onTap: _openWardrobe,
                body: Text('Wearing ${game.outfit.name}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              const SizedBox(height: 24),

              // 오늘 기록
              _title('Today'),
              WalkRecordCard(steps: game.stepsOn(DateTime.now()), emptyText: 'No walk yet today'),
              const SizedBox(height: 24),

              // 달력
              _title('Walk history'),
              _calendar(),
              // 오늘은 위의 Today 박스에 이미 있으니, 다른 날을 골랐을 때만 표시
              if (_selected != null && !_sameDay(_selected!, DateTime.now())) ...[
                const SizedBox(height: 12),
                Text('${_monthNames[_selected!.month - 1]} ${_selected!.day}, ${_selected!.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                WalkRecordCard(steps: game.stepsOn(_selected!), emptyText: 'No walk recorded'),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  /// 한 달짜리 달력. 걸은 날은 칸이 칠해지고 걸은 거리(km)가 표시됨
  Widget _calendar() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = _month.weekday % 7; // 일요일부터 시작
    final isThisMonth = _month.year == now.year && _month.month == now.month;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    setState(() => _month = DateTime(_month.year, _month.month - 1)),
              ),
              Expanded(
                child: Text('${_monthNames[_month.month - 1]} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: isThisMonth
                    ? null // 미래 달로는 못 넘어감
                    : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              ),
            ],
          ),
          Row(
            children: [
              for (final w in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(
                  child: Text(w,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.9,
            children: [
              for (var i = 0; i < offset; i++) const SizedBox.shrink(),
              for (var d = 1; d <= daysInMonth; d++)
                _dayCell(DateTime(_month.year, _month.month, d), today),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime date, DateTime today) {
    final future = date.isAfter(today);
    final steps = game.stepsOn(date);
    final isToday = _sameDay(date, today);
    final selected = _selected != null && _sameDay(_selected!, date);

    return InkWell(
      onTap: future ? null : () => setState(() => _selected = date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: steps > 0 ? Colors.grey.shade300 : null,
          border: selected
              ? Border.all(color: Colors.grey.shade800, width: 2)
              : isToday
                  ? Border.all(color: Colors.grey)
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  color: future ? Colors.grey.shade400 : null,
                  fontWeight: isToday ? FontWeight.bold : null,
                )),
            if (steps > 0)
              Text('${(steps * kStepLengthKm).toStringAsFixed(1)}km',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

/// 이름 바꾸기 창 (입력칸을 이 창이 직접 관리해서 닫힐 때 안전하게 정리됨)
class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initial});
  final String initial;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(hintText: 'Your name'),
        onSubmitted: (v) => Navigator.pop(context, v), // 엔터로도 저장
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}