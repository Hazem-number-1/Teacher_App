// ============================================================================
//  فلاتر سوشيال  |  SocialVerse (XUS)  -  مربوط بـ Supabase
//  ملف واحد - يعمل على Chrome والهواتف
//
//  التشغيل:
//    flutter pub add supabase_flutter
//    استبدل محتوى lib/main.dart بهذا الملف
//    flutter run -d chrome
// ============================================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String kSupabaseUrl = 'https://yuqmmcpizfdouqcrspge.supabase.co';
const String kSupabasePublishableKey =
    'sb_publishable_Tb7LV5i3c2GoSqZirjpn4Q__oxXfyzp';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: kSupabaseUrl,
    publishableKey: kSupabasePublishableKey,
  );
  runApp(const SocialVerseApp());
}

// ─────────────────────────────────────────────────────────────────────────────
//  الألوان والثيم
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();
  static const Color bg = Color(0xFFF0F4FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFE9EFF8);
  static const Color ink = Color(0xFF0F172A);
  static const Color blue = Color(0xFF0175C2);
  static const Color cyan = Color(0xFF0AA5E8);
  static const Color textDim = Color(0xFF64748B);
  static const Color danger = Color(0xFFE5365A);
  static const Color success = Color(0xFF10B981);
  static const LinearGradient brand = LinearGradient(
    colors: [blue, cyan],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
}

const List<List<Color>> kGradients = [
  [Color(0xFF0175C2), Color(0xFF13B9FD)],
  [Color(0xFFFF6B6B), Color(0xFFFFB86B)],
  [Color(0xFF7F5AF0), Color(0xFFE45AF0)],
  [Color(0xFF16A085), Color(0xFF6EE7B7)],
  [Color(0xFFF72585), Color(0xFFB5179E)],
  [Color(0xFFFFC837), Color(0xFFFF8008)],
];

const List<String> kAvatarEmojis = [
  '😎',
  '🦊',
  '🐱',
  '🐼',
  '🦁',
  '🚀',
  '🎨',
  '🎧',
  '⚽',
  '🌸',
  '🔥',
  '⭐',
];

Color alpha(Color c, double opacity) =>
    c.withAlpha((opacity * 255).round().clamp(0, 255));

LinearGradient gradientOf(int i) => LinearGradient(
  colors: kGradients[i % kGradients.length],
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
);

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'الآن';
  if (d.inMinutes < 60) return 'منذ ${d.inMinutes} دقيقة';
  if (d.inHours < 24) return 'منذ ${d.inHours} ساعة';
  return 'منذ ${d.inDays} يوم';
}

void showMsg(BuildContext context, String msg) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
    ),
  );
}

ThemeData buildTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.blue,
    onPrimary: Colors.white,
    secondary: AppColors.cyan,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

InputDecoration inputDeco(
  String label,
  IconData icon, {
  Widget? suffix,
  String? hint,
}) {
  OutlineInputBorder border(Color c, [double w = 0]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: AppColors.textDim),
    hintStyle: const TextStyle(color: AppColors.textDim),
    prefixIcon: Icon(icon, size: 20, color: AppColors.textDim),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.surface2,
    border: border(Colors.transparent),
    enabledBorder: border(Colors.transparent),
    focusedBorder: border(AppColors.cyan, 1.5),
    errorBorder: border(AppColors.danger, 1.2),
    focusedErrorBorder: border(AppColors.danger, 1.5),
  );
}

BoxDecoration cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: alpha(AppColors.ink, 0.05)),
  boxShadow: [
    BoxShadow(
      color: alpha(AppColors.ink, 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
//  النماذج (Models)
// ─────────────────────────────────────────────────────────────────────────────

enum Audience {
  everyone('عام', Icons.public),
  friends('الأصدقاء', Icons.group_outlined),
  custom('قوائم محددة', Icons.list_alt_rounded),
  onlyMe('أنا فقط', Icons.lock_outline);

  final String label;
  final IconData icon;
  const Audience(this.label, this.icon);

  static Audience fromDb(String? raw) {
    switch (raw) {
      case 'friends':
        return Audience.friends;
      case 'custom':
        return Audience.custom;
      case 'onlyMe':
      case 'only_me':
        return Audience.onlyMe;
      default:
        return Audience.everyone;
    }
  }
}

enum Reaction {
  like('👍', 'أعجبني', Color(0xFF2D88FF)),
  love('❤️', 'أحببته', Color(0xFFF3425F)),
  haha('😆', 'هاها', Color(0xFFF7B125)),
  wow('😮', 'واو', Color(0xFFF7B125)),
  sad('😢', 'حزين', Color(0xFFF7B125)),
  angry('😡', 'غاضب', Color(0xFFE9710F));

  final String emoji;
  final String label;
  final Color color;
  const Reaction(this.emoji, this.label, this.color);
}

enum AttachKind {
  image('صورة', Icons.image_outlined),
  video('فيديو', Icons.videocam_outlined),
  document('ملف / مستند', Icons.description_outlined),
  link('رابط', Icons.link_rounded);

  final String label;
  final IconData icon;
  const AttachKind(this.label, this.icon);
}

class Attachment {
  final String id;
  final AttachKind kind;
  final String name;
  final String? url;
  final int sizeKb;
  final int color;
  const Attachment({
    required this.id,
    required this.kind,
    required this.name,
    this.url,
    this.sizeKb = 0,
    this.color = 0,
  });
}

String sizeText(int kb) =>
    kb < 1024 ? '$kb ك.ب' : '${(kb / 1024).toStringAsFixed(1)} م.ب';

String fmtDuration(int s) {
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final r = (s % 60).toString().padLeft(2, '0');
  return '$m:$r';
}

enum NotifType {
  friend(Icons.person_add_alt_1_rounded, Color(0xFF0AA5E8)),
  reaction(Icons.favorite_rounded, Color(0xFFF3425F)),
  comment(Icons.chat_bubble_rounded, Color(0xFF10B981)),
  group(Icons.groups_rounded, Color(0xFFF59E0B)),
  message(Icons.mark_chat_unread_rounded, Color(0xFF7F5AF0));

  final IconData icon;
  final Color color;
  const NotifType(this.icon, this.color);

  static NotifType fromDb(String? raw) {
    for (final t in NotifType.values) {
      if (t.name == raw) return t;
    }
    return NotifType.friend;
  }
}

class AppNotification {
  final String id;
  final String toId;
  final NotifType type;
  final String text;
  final DateTime created;
  bool read = false;
  AppNotification({
    required this.id,
    required this.toId,
    required this.type,
    required this.text,
    required this.created,
    this.read = false,
  });
}

class FriendList {
  final String id;
  String name;
  String emoji;
  final Set<String> members = <String>{};
  FriendList({required this.id, required this.name, required this.emoji});
}

class Group {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final bool isPrivate;
  final bool isPage;
  final String category;
  final int gradient;
  final DateTime created;
  final Set<String> members = <String>{};
  final Set<String> admins = <String>{};

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.isPrivate,
    required this.gradient,
    required this.created,
    this.isPage = false,
    this.category = '',
  });

  String get typeLabel => isPage
      ? 'صفحة${category.isEmpty ? '' : ' • $category'}'
      : (isPrivate ? 'مجموعة خاصة' : 'مجموعة عامة');

  String get countLabel =>
      isPage ? '${members.length} متابع' : '${members.length} عضو';
}

class ChatMessage {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final DateTime created;
  final Attachment? attachment;
  final String? callLabel;
  final bool callVideo;
  bool read = false;

  ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.created,
    this.attachment,
    this.callLabel,
    this.callVideo = false,
    this.read = false,
  });
}

class Conversation {
  final Account other;
  final ChatMessage last;
  final int unread;
  const Conversation({
    required this.other,
    required this.last,
    required this.unread,
  });
}

const List<String> kRelations = [
  'أم',
  'أب',
  'أخ',
  'أخت',
  'ابن',
  'ابنة',
  'زوج',
  'زوجة',
  'جد',
  'جدة',
  'عم / خال',
  'عمة / خالة',
  'قريب',
];

const List<String> kListEmojis = [
  '👨‍👩‍👧',
  '⭐',
  '🎓',
  '💼',
  '🏠',
  '⚽',
  '🎮',
  '🎨',
  '✈️',
  '❤️',
];

const List<String> kChatEmojis = [
  '😀',
  '😃',
  '😄',
  '😁',
  '😆',
  '😅',
  '🤣',
  '😂',
  '🙂',
  '😉',
  '😊',
  '😇',
  '🥰',
  '😍',
  '🤩',
  '😘',
  '😋',
  '😛',
  '😜',
  '🤪',
  '🤗',
  '🤔',
  '🤨',
  '😐',
  '😶',
  '🙄',
  '😏',
  '😴',
  '😎',
  '🤓',
  '🧐',
  '😕',
  '😟',
  '🙁',
  '😮',
  '😲',
  '😳',
  '🥺',
  '😢',
  '😭',
  '😤',
  '😠',
  '😡',
  '🤯',
  '😱',
  '🥶',
  '🥵',
  '🤒',
  '🥳',
  '👍',
  '👎',
  '👏',
  '🙌',
  '🙏',
  '💪',
  '👌',
  '✌️',
  '🤝',
  '❤️',
  '🧡',
  '💛',
  '💚',
  '💙',
  '💜',
  '🔥',
  '✨',
  '🎉',
  '💯',
];

const List<String> kFilterNames = [
  'بدون',
  'دافئ',
  'بارد',
  'أبيض وأسود',
  'قديم',
  'نيون',
];

const List<List<double>> kFilterMatrices = [
  [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
  [1.2, 0, 0, 0, 10, 0, 1, 0, 0, 0, 0, 0, 0.8, 0, 0, 0, 0, 0, 1, 0],
  [0.85, 0, 0, 0, 0, 0, 1, 0, 0, 5, 0, 0, 1.2, 0, 15, 0, 0, 0, 1, 0],
  [
    0.33,
    0.59,
    0.11,
    0,
    0,
    0.33,
    0.59,
    0.11,
    0,
    0,
    0.33,
    0.59,
    0.11,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ],
  [
    0.393,
    0.769,
    0.189,
    0,
    0,
    0.349,
    0.686,
    0.168,
    0,
    0,
    0.272,
    0.534,
    0.131,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ],
  [1.4, 0, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0, 1.5, 0, 20, 0, 0, 0, 1, 0],
];

class Account {
  final String id;
  final String email;
  final String password;

  String name = '';
  String bio = '';
  int gradient = 0;
  String emoji = '';
  bool onboarded = false;

  Audience defaultAudience = Audience.everyone;
  bool allowRequests = true;
  bool showFriends = true;
  bool allowComments = true;
  bool notifications = true;

  final Set<String> friends = <String>{};
  final Set<String> incoming = <String>{};
  final Set<String> outgoing = <String>{};
  final Set<String> blocked = <String>{};
  final List<FriendList> lists = <FriendList>[];
  final Map<String, String> relations = <String, String>{};
  Audience whoCanMessage = Audience.everyone;

  Account({required this.id, required this.email, this.password = ''});
}

class Comment {
  final String authorId;
  final String text;
  const Comment(this.authorId, this.text);
}

class Post {
  final String id;
  final String authorId;
  final DateTime created;
  final String text;
  final Audience audience;
  final Map<String, Reaction> reactions = <String, Reaction>{};
  final List<Comment> comments = <Comment>[];
  final List<Attachment> attachments;
  final String? groupId;
  final String? linkedPostId;
  final Set<String> listIds;
  final Set<String> hiddenFrom;
  int shares = 0;

  Post({
    required this.id,
    required this.authorId,
    required this.created,
    required this.text,
    required this.audience,
    List<Attachment>? attachments,
    this.groupId,
    this.linkedPostId,
    Set<String>? listIds,
    Set<String>? hiddenFrom,
    this.shares = 0,
  }) : attachments = attachments ?? <Attachment>[],
       listIds = listIds ?? <String>{},
       hiddenFrom = hiddenFrom ?? <String>{};

  Map<Reaction, int> get counts {
    final m = <Reaction, int>{};
    for (final r in reactions.values) {
      m[r] = (m[r] ?? 0) + 1;
    }
    return m;
  }

  int get total => reactions.length;
}

class Story {
  final String id;
  final String authorId;
  final String text;
  final int gradient;
  final DateTime created;
  const Story({
    required this.id,
    required this.authorId,
    required this.text,
    required this.gradient,
    required this.created,
  });
}

enum FriendState { none, friends, incoming, outgoing }

// ─────────────────────────────────────────────────────────────────────────────
//  المتجر (AppStore): متصل بقاعدة بيانات Supabase
// ─────────────────────────────────────────────────────────────────────────────

class AppStore extends ChangeNotifier {
  AppStore({required this.notice}) {
    _bootstrapAuth();
  }

  final void Function(String message) notice;
  final SupabaseClient _db = Supabase.instance.client;

  final Map<String, Account> _byEmail = <String, Account>{};
  final Map<String, Account> _byId = <String, Account>{};
  final List<Post> posts = <Post>[];
  final List<Story> stories = <Story>[];
  final List<Group> groups = <Group>[];
  final List<AppNotification> notifications = <AppNotification>[];
  final List<ChatMessage> messages = <ChatMessage>[];
  Account? me;
  int _seq = 0;
  bool offline = false;

  void _bootstrapAuth() {
    final currentUser = _db.auth.currentUser;
    if (currentUser != null) {
      unawaited(_syncFromSupabase(currentUser));
    }
    _db.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user == null) {
        me = null;
        notifyListeners();
      } else {
        unawaited(_syncFromSupabase(user));
      }
    });
  }

  Future<void> _syncFromSupabase(User authUser) async {
    try {
      final profRows = await _db.from('profiles').select();
      _byId.clear();
      _byEmail.clear();
      for (final row in (profRows as List)) {
        final m = Map<String, dynamic>.from(row as Map);
        final acc =
            Account(
                id: (m['id'] ?? '').toString(),
                email: (m['email'] ?? '').toString(),
              )
              ..name = (m['name'] ?? '').toString()
              ..bio = (m['bio'] ?? '').toString()
              ..gradient = (m['gradient'] as num?)?.toInt() ?? 0
              ..emoji = (m['emoji'] ?? '').toString()
              ..onboarded = m['onboarded'] == true
              ..defaultAudience = Audience.fromDb(
                m['default_audience']?.toString(),
              )
              ..whoCanMessage = Audience.fromDb(
                m['who_can_message']?.toString(),
              )
              ..allowRequests = m['allow_requests'] != false
              ..showFriends = m['show_friends'] != false
              ..allowComments = m['allow_comments'] != false
              ..notifications = m['notifications'] != false;

        acc.lists.addAll([
          FriendList(id: newId('l'), name: 'العائلة', emoji: '👨‍👩‍👧'),
          FriendList(id: newId('l'), name: 'أصدقاء مقرّبون', emoji: '⭐'),
          FriendList(id: newId('l'), name: 'زملاء العمل والدراسة', emoji: '🎓'),
        ]);

        _byId[acc.id] = acc;
        if (acc.email.isNotEmpty) {
          _byEmail[acc.email.toLowerCase()] = acc;
        }
      }

      if (!_byId.containsKey(authUser.id)) {
        final email = authUser.email ?? '';
        await _db.from('profiles').upsert({
          'id': authUser.id,
          'email': email,
          'name': '',
          'onboarded': false,
        });
        final fresh = Account(id: authUser.id, email: email)
          ..lists.addAll([
            FriendList(id: newId('l'), name: 'العائلة', emoji: '👨‍👩‍👧'),
            FriendList(id: newId('l'), name: 'أصدقاء مقرّبون', emoji: '⭐'),
            FriendList(
              id: newId('l'),
              name: 'زملاء العمل والدراسة',
              emoji: '🎓',
            ),
          ]);
        _byId[fresh.id] = fresh;
        if (email.isNotEmpty) _byEmail[email.toLowerCase()] = fresh;
      }

      me = _byId[authUser.id];

      final friendRows = await _db.from('friendships').select();
      for (final r in (friendRows as List)) {
        final m = Map<String, dynamic>.from(r as Map);
        final reqId = (m['requester_id'] ?? '').toString();
        final addId = (m['addressee_id'] ?? '').toString();
        final status = (m['status'] ?? 'pending').toString();
        final req = _byId[reqId];
        final add = _byId[addId];
        if (req == null || add == null) continue;
        if (status == 'accepted') {
          req.friends.add(add.id);
          add.friends.add(req.id);
        } else if (status == 'pending') {
          req.outgoing.add(add.id);
          add.incoming.add(req.id);
        } else if (status == 'blocked') {
          req.blocked.add(add.id);
        }
      }

      final groupRows = await _db
          .from('groups')
          .select()
          .order('created_at', ascending: false);
      groups.clear();
      final groupMap = <String, Group>{};
      for (final r in (groupRows as List)) {
        final m = Map<String, dynamic>.from(r as Map);
        final g = Group(
          id: (m['id'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          description: (m['description'] ?? '').toString(),
          ownerId: (m['owner_id'] ?? '').toString(),
          isPrivate: m['is_private'] == true,
          isPage: m['is_page'] == true,
          category: (m['category'] ?? '').toString(),
          gradient: (m['gradient'] as num?)?.toInt() ?? 0,
          created:
              DateTime.tryParse((m['created_at'] ?? '').toString()) ??
              DateTime.now(),
        );
        g.members.add(g.ownerId);
        g.admins.add(g.ownerId);
        groups.add(g);
        groupMap[g.id] = g;
      }

      final memberRows = await _db.from('group_members').select();
      for (final r in (memberRows as List)) {
        final m = Map<String, dynamic>.from(r as Map);
        final g = groupMap[(m['group_id'] ?? '').toString()];
        final uid = (m['user_id'] ?? '').toString();
        if (g == null || uid.isEmpty) continue;
        g.members.add(uid);
        if (m['is_admin'] == true) g.admins.add(uid);
      }

      final postRows = await _db
          .from('posts')
          .select()
          .order('created_at', ascending: false);
      posts.clear();
      final postMap = <String, Post>{};
      for (final r in (postRows as List)) {
        final m = Map<String, dynamic>.from(r as Map);
        final p = Post(
          id: (m['id'] ?? '').toString(),
          authorId: (m['author_id'] ?? '').toString(),
          created:
              DateTime.tryParse((m['created_at'] ?? '').toString()) ??
              DateTime.now(),
          text: (m['text'] ?? '').toString(),
          audience: Audience.fromDb(m['audience']?.toString()),
          groupId: m['group_id']?.toString(),
          linkedPostId: m['linked_post_id']?.toString(),
          shares: (m['shares'] as num?)?.toInt() ?? 0,
        );
        posts.add(p);
        postMap[p.id] = p;
      }

      final commentRows = await _db
          .from('comments')
          .select()
          .order('created_at', ascending: true);
      for (final r in (commentRows as List)) {
        final m = Map<String, dynamic>.from(r as Map);
        final p = postMap[(m['post_id'] ?? '').toString()];
        if (p != null) {
          p.comments.add(
            Comment(
              (m['author_id'] ?? '').toString(),
              (m['text'] ?? '').toString(),
            ),
          );
        }
      }

      final msgRows = await _db
          .from('messages')
          .select()
          .order('created_at', ascending: true);
      messages.clear();
      for (final r in (msgRows as List)) {
        final m = Map<String, dynamic>.from(r as Map);
        messages.add(
          ChatMessage(
            id: (m['id'] ?? '').toString(),
            fromId: (m['sender_id'] ?? '').toString(),
            toId: (m['receiver_id'] ?? '').toString(),
            text: (m['text'] ?? '').toString(),
            created:
                DateTime.tryParse((m['created_at'] ?? '').toString()) ??
                DateTime.now(),
            read: m['is_read'] == true,
          ),
        );
      }

      final notifRows = await _db
          .from('notifications')
          .select()
          .order('created_at', ascending: false);
      notifications.clear();
      for (final r in (notifRows as List)) {
        final m = Map<String, dynamic>.from(r as Map);
        notifications.add(
          AppNotification(
            id: (m['id'] ?? '').toString(),
            toId: (m['to_id'] ?? '').toString(),
            type: NotifType.fromDb(m['type']?.toString()),
            text: (m['text'] ?? '').toString(),
            created:
                DateTime.tryParse((m['created_at'] ?? '').toString()) ??
                DateTime.now(),
            read: m['is_read'] == true,
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      notice('تعذّر مزامنة البيانات مع Supabase: $e');
    }
  }

  Account? byId(String id) => _byId[id];

  Post? postById(String id) {
    for (final p in posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Group? groupById(String id) {
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  String newId(String prefix) {
    _seq++;
    return '$prefix$_seq';
  }

  bool denyIfOffline() {
    if (!offline) return false;
    notice('لا يوجد اتصال بالإنترنت — وضع القراءة فقط');
    return true;
  }

  void setOffline(bool v) {
    offline = v;
    notifyListeners();
  }

  bool blockedBetween(Account a, Account b) =>
      a.blocked.contains(b.id) || b.blocked.contains(a.id);

  // ───── الحسابات
  Future<String?> signUpAsync(String email, String password) async {
    final key = email.trim().toLowerCase();
    try {
      final res = await _db.auth.signUp(email: key, password: password);
      final user = res.user;
      if (user == null) {
        return 'تم إرسال رابط التفعيل إلى بريدك الإلكتروني أو تعذّر إنشاء الحساب';
      }
      await _db.from('profiles').upsert({
        'id': user.id,
        'email': key,
        'name': '',
        'onboarded': false,
      });
      await _syncFromSupabase(user);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'حدث خطأ أثناء إنشاء الحساب: $e';
    }
  }

  Future<String?> logInAsync(String email, String password) async {
    final key = email.trim().toLowerCase();
    try {
      final res = await _db.auth.signInWithPassword(
        email: key,
        password: password,
      );
      final user = res.user;
      if (user == null) return 'بيانات الدخول غير صحيحة';
      await _syncFromSupabase(user);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'تعذّر تسجيل الدخول: $e';
    }
  }

  String? signUp(String email, String password) {
    unawaited(signUpAsync(email, password));
    return null;
  }

  String? logIn(String email, String password) {
    unawaited(logInAsync(email, password));
    return null;
  }

  void googleDemo() {
    notice('تسجيل Google يتطلب تفعيله من لوحة Supabase Auth');
  }

  void logOut() {
    unawaited(_db.auth.signOut());
    me = null;
    notifyListeners();
  }

  void completeOnboarding(String name, int gradient, String emoji) {
    final a = me;
    if (a == null) return;
    a.name = name.trim();
    a.gradient = gradient;
    a.emoji = emoji;
    a.onboarded = true;
    notifyListeners();
    unawaited(
      _db
          .from('profiles')
          .update({
            'name': a.name,
            'gradient': a.gradient,
            'emoji': a.emoji,
            'onboarded': true,
          })
          .eq('id', a.id),
    );
  }

  bool updateProfile(String name, String bio, int gradient, String emoji) {
    final a = me;
    if (a == null || denyIfOffline()) return false;
    a.name = name.trim();
    a.bio = bio.trim();
    a.gradient = gradient;
    a.emoji = emoji;
    notifyListeners();
    unawaited(
      _db
          .from('profiles')
          .update({
            'name': a.name,
            'bio': a.bio,
            'gradient': a.gradient,
            'emoji': a.emoji,
          })
          .eq('id', a.id),
    );
    return true;
  }

  // ───── الخصوصية
  void setDefaultAudience(Audience v) {
    if (denyIfOffline()) return;
    final a = me;
    if (a == null) return;
    a.defaultAudience = v;
    notifyListeners();
    unawaited(
      _db.from('profiles').update({'default_audience': v.name}).eq('id', a.id),
    );
  }

  void setWhoCanMessage(Audience v) {
    if (denyIfOffline()) return;
    final a = me;
    if (a == null) return;
    a.whoCanMessage = v;
    notifyListeners();
    unawaited(
      _db.from('profiles').update({'who_can_message': v.name}).eq('id', a.id),
    );
  }

  void setAllowRequests(bool v) {
    if (denyIfOffline()) return;
    final a = me;
    if (a == null) return;
    a.allowRequests = v;
    notifyListeners();
    unawaited(
      _db.from('profiles').update({'allow_requests': v}).eq('id', a.id),
    );
  }

  void setShowFriends(bool v) {
    if (denyIfOffline()) return;
    final a = me;
    if (a == null) return;
    a.showFriends = v;
    notifyListeners();
    unawaited(_db.from('profiles').update({'show_friends': v}).eq('id', a.id));
  }

  void setAllowComments(bool v) {
    if (denyIfOffline()) return;
    final a = me;
    if (a == null) return;
    a.allowComments = v;
    notifyListeners();
    unawaited(
      _db.from('profiles').update({'allow_comments': v}).eq('id', a.id),
    );
  }

  void setNotifications(bool v) {
    if (denyIfOffline()) return;
    final a = me;
    if (a == null) return;
    a.notifications = v;
    notifyListeners();
    unawaited(_db.from('profiles').update({'notifications': v}).eq('id', a.id));
  }

  // ───── الحظر
  void block(Account other) {
    final a = me;
    if (a == null || denyIfOffline()) return;
    a.blocked.add(other.id);
    a.friends.remove(other.id);
    other.friends.remove(a.id);
    a.incoming.remove(other.id);
    a.outgoing.remove(other.id);
    other.incoming.remove(a.id);
    other.outgoing.remove(a.id);
    for (final l in a.lists) {
      l.members.remove(other.id);
    }
    a.relations.remove(other.id);
    notifyListeners();
    unawaited(
      _db.from('friendships').upsert({
        'requester_id': a.id,
        'addressee_id': other.id,
        'status': 'blocked',
      }, onConflict: 'requester_id,addressee_id'),
    );
  }

  void unblock(Account other) {
    final a = me;
    if (a == null || denyIfOffline()) return;
    a.blocked.remove(other.id);
    notifyListeners();
    unawaited(
      _db
          .from('friendships')
          .delete()
          .eq('requester_id', a.id)
          .eq('addressee_id', other.id)
          .eq('status', 'blocked'),
    );
  }

  // ───── رؤية المحتوى
  bool canSeePost(Post p) {
    final viewer = me;
    if (viewer == null) return false;
    if (p.authorId == viewer.id) return true;
    final author = _byId[p.authorId];
    if (author == null || blockedBetween(viewer, author)) return false;
    if (p.hiddenFrom.contains(viewer.id)) return false;
    final gid = p.groupId;
    if (gid != null) {
      final g = groupById(gid);
      if (g == null) return false;
      return g.members.contains(viewer.id) || !g.isPrivate;
    }
    if (p.audience == Audience.everyone) return true;
    if (p.audience == Audience.friends) {
      return author.friends.contains(viewer.id);
    }
    if (p.audience == Audience.custom) {
      for (final l in author.lists) {
        if (p.listIds.contains(l.id) && l.members.contains(viewer.id)) {
          return true;
        }
      }
      return false;
    }
    return false;
  }

  List<Post> visiblePosts() =>
      posts.where((p) => p.groupId == null && canSeePost(p)).toList();

  List<Post> postsOf(Account a) =>
      posts.where((p) => p.authorId == a.id && canSeePost(p)).toList();

  List<Post> groupPosts(Group g) =>
      posts.where((p) => p.groupId == g.id && canSeePost(p)).toList();

  List<Story> visibleStories() {
    final viewer = me;
    if (viewer == null) return <Story>[];
    final limit = DateTime.now().subtract(const Duration(hours: 24));
    return stories.where((s) {
      if (s.created.isBefore(limit)) return false;
      if (s.authorId == viewer.id) return true;
      final author = _byId[s.authorId];
      if (author == null || blockedBetween(viewer, author)) return false;
      return author.friends.contains(viewer.id);
    }).toList();
  }

  // ───── الإشعارات
  void _push(Account to, NotifType type, String text) {
    final from = me;
    if (from == null || to.id == from.id || !to.notifications) return;
    final item = AppNotification(
      id: newId('n'),
      toId: to.id,
      type: type,
      text: text,
      created: DateTime.now(),
    );
    notifications.insert(0, item);
    unawaited(
      _db.from('notifications').insert({
        'to_id': to.id,
        'type': type.name,
        'text': text,
        'is_read': false,
      }),
    );
  }

  List<AppNotification> myNotifications() =>
      notifications.where((n) => n.toId == me?.id).toList();

  int get unreadCount =>
      notifications.where((n) => n.toId == me?.id && !n.read).length;

  void markRead(AppNotification n) {
    if (n.read) return;
    n.read = true;
    notifyListeners();
    if (n.id.length > 10) {
      unawaited(
        _db.from('notifications').update({'is_read': true}).eq('id', n.id),
      );
    }
  }

  void markAllRead() {
    final uid = me?.id;
    if (uid == null) return;
    for (final n in notifications) {
      if (n.toId == uid) n.read = true;
    }
    notifyListeners();
    unawaited(
      _db.from('notifications').update({'is_read': true}).eq('to_id', uid),
    );
  }

  // ───── المنشورات
  bool addPost(
    String text,
    Audience audience, {
    List<Attachment>? attachments,
    String? groupId,
    String? linkedPostId,
    Set<String>? listIds,
    Set<String>? hiddenFrom,
  }) {
    final a = me;
    if (a == null) return false;
    final atts = attachments ?? <Attachment>[];
    if (text.trim().isEmpty && atts.isEmpty && linkedPostId == null) {
      return false;
    }
    if (denyIfOffline()) return false;
    if (groupId != null) {
      final g = groupById(groupId);
      if (g == null) return false;
      final allowed = g.isPage
          ? g.admins.contains(a.id)
          : g.members.contains(a.id);
      if (!allowed) return false;
    }
    final effAudience = groupId != null ? Audience.everyone : audience;
    final post = Post(
      id: newId('p'),
      authorId: a.id,
      created: DateTime.now(),
      text: text.trim(),
      audience: effAudience,
      attachments: atts,
      groupId: groupId,
      linkedPostId: linkedPostId,
      listIds: listIds,
      hiddenFrom: hiddenFrom,
    );
    posts.insert(0, post);
    notifyListeners();
    unawaited(
      _db
          .from('posts')
          .insert({
            'author_id': a.id,
            'text': post.text,
            'audience': effAudience.name,
            'group_id': groupId,
            'linked_post_id': linkedPostId,
            'shares': 0,
          })
          .select()
          .then((rows) {
            if (rows.isNotEmpty) {
              final insertedId = (rows.first['id'] ?? '').toString();
              if (insertedId.isNotEmpty) {
                final idx = posts.indexOf(post);
                if (idx != -1) {
                  posts[idx] =
                      Post(
                          id: insertedId,
                          authorId: post.authorId,
                          created: post.created,
                          text: post.text,
                          audience: post.audience,
                          attachments: post.attachments,
                          groupId: post.groupId,
                          linkedPostId: post.linkedPostId,
                          listIds: post.listIds,
                          hiddenFrom: post.hiddenFrom,
                          shares: post.shares,
                        )
                        ..reactions.addAll(post.reactions)
                        ..comments.addAll(post.comments);
                  notifyListeners();
                }
              }
            }
          }),
    );
    return true;
  }

  void deletePost(Post p) {
    if (me?.id != p.authorId || denyIfOffline()) return;
    posts.remove(p);
    notifyListeners();
    if (p.id.length > 10) {
      unawaited(_db.from('posts').delete().eq('id', p.id));
    }
  }

  bool react(Post p, Reaction r) {
    final a = me;
    if (a == null || denyIfOffline()) return false;
    if (p.reactions[a.id] == r) {
      p.reactions.remove(a.id);
    } else {
      p.reactions[a.id] = r;
      final au = _byId[p.authorId];
      if (au != null) {
        _push(au, NotifType.reaction, '${a.name} تفاعل ${r.emoji} مع منشورك');
      }
    }
    notifyListeners();
    return true;
  }

  bool addComment(Post p, String text) {
    final a = me;
    if (a == null || text.trim().isEmpty || denyIfOffline()) return false;
    final clean = text.trim();
    p.comments.add(Comment(a.id, clean));
    final au = _byId[p.authorId];
    if (au != null) {
      _push(au, NotifType.comment, '${a.name} علّق على منشورك');
    }
    notifyListeners();
    if (p.id.length > 10) {
      unawaited(
        _db.from('comments').insert({
          'post_id': p.id,
          'author_id': a.id,
          'text': clean,
        }),
      );
    }
    return true;
  }

  void share(Post p) {
    p.shares += 1;
    notifyListeners();
    if (p.id.length > 10) {
      unawaited(_db.from('posts').update({'shares': p.shares}).eq('id', p.id));
    }
  }

  bool addStory(String text, int gradient) {
    final a = me;
    if (a == null || text.trim().isEmpty || denyIfOffline()) return false;
    stories.insert(
      0,
      Story(
        id: newId('s'),
        authorId: a.id,
        text: text.trim(),
        gradient: gradient,
        created: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  // ───── الأصدقاء والاقتراحات
  int mutualCount(Account other) {
    final a = me;
    if (a == null) return 0;
    return a.friends.intersection(other.friends).length;
  }

  List<Account> people() {
    final a = me;
    if (a == null) return <Account>[];
    final list = _byId.values
        .where(
          (o) =>
              o.id != a.id &&
              o.onboarded &&
              !a.friends.contains(o.id) &&
              !blockedBetween(a, o),
        )
        .toList();
    list.sort((x, y) {
      final c = mutualCount(y).compareTo(mutualCount(x));
      return c != 0 ? c : x.name.compareTo(y.name);
    });
    return list;
  }

  FriendState stateWith(Account other) {
    final a = me;
    if (a == null) return FriendState.none;
    if (a.friends.contains(other.id)) return FriendState.friends;
    if (a.incoming.contains(other.id)) return FriendState.incoming;
    if (a.outgoing.contains(other.id)) return FriendState.outgoing;
    return FriendState.none;
  }

  bool sendRequest(Account other) {
    final a = me;
    if (a == null || denyIfOffline()) return false;
    if (!other.allowRequests || blockedBetween(a, other)) return false;
    if (a.incoming.contains(other.id)) return accept(other);
    a.outgoing.add(other.id);
    other.incoming.add(a.id);
    _push(other, NotifType.friend, '${a.name} أرسل لك طلب صداقة');
    notifyListeners();
    unawaited(
      _db.from('friendships').upsert({
        'requester_id': a.id,
        'addressee_id': other.id,
        'status': 'pending',
      }, onConflict: 'requester_id,addressee_id'),
    );
    return true;
  }

  void cancelRequest(Account other) {
    final a = me;
    if (a == null || denyIfOffline()) return;
    a.outgoing.remove(other.id);
    other.incoming.remove(a.id);
    notifyListeners();
    unawaited(
      _db
          .from('friendships')
          .delete()
          .eq('requester_id', a.id)
          .eq('addressee_id', other.id),
    );
  }

  bool accept(Account other) {
    final a = me;
    if (a == null || denyIfOffline()) return false;
    a.incoming.remove(other.id);
    other.outgoing.remove(a.id);
    a.friends.add(other.id);
    other.friends.add(a.id);
    _push(other, NotifType.friend, '${a.name} قبل طلب صداقتك');
    notifyListeners();
    unawaited(
      _db
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('requester_id', other.id)
          .eq('addressee_id', a.id),
    );
    return true;
  }

  void decline(Account other) {
    final a = me;
    if (a == null || denyIfOffline()) return;
    a.incoming.remove(other.id);
    other.outgoing.remove(a.id);
    notifyListeners();
    unawaited(
      _db
          .from('friendships')
          .delete()
          .eq('requester_id', other.id)
          .eq('addressee_id', a.id),
    );
  }

  bool unfriend(Account other) {
    final a = me;
    if (a == null || denyIfOffline()) return false;
    a.friends.remove(other.id);
    other.friends.remove(a.id);
    for (final l in a.lists) {
      l.members.remove(other.id);
    }
    a.relations.remove(other.id);
    notifyListeners();
    unawaited(
      _db
          .from('friendships')
          .delete()
          .or(
            'and(requester_id.eq.${a.id},addressee_id.eq.${other.id}),and(requester_id.eq.${other.id},addressee_id.eq.${a.id})',
          ),
    );
    return true;
  }

  // ───── قوائم الأصدقاء وصلات القرابة
  FriendList? createList(String name, String emoji) {
    final a = me;
    if (a == null || name.trim().isEmpty || denyIfOffline()) return null;
    final l = FriendList(id: newId('l'), name: name.trim(), emoji: emoji);
    a.lists.add(l);
    notifyListeners();
    return l;
  }

  void deleteList(FriendList l) {
    final a = me;
    if (a == null || denyIfOffline()) return;
    a.lists.remove(l);
    notifyListeners();
  }

  void setListMembers(FriendList l, Set<String> ids) {
    final a = me;
    if (a == null || denyIfOffline()) return;
    l.members
      ..clear()
      ..addAll(ids.where(a.friends.contains));
    notifyListeners();
  }

  void setRelation(Account friend, String? label) {
    final a = me;
    if (a == null || denyIfOffline()) return;
    if (label == null || label.isEmpty) {
      a.relations.remove(friend.id);
    } else {
      a.relations[friend.id] = label;
    }
    notifyListeners();
  }

  // ───── المجموعات والصفحات
  List<Group> myGroups() {
    final a = me;
    if (a == null) return <Group>[];
    return groups.where((g) => g.members.contains(a.id)).toList();
  }

  List<Group> discoverGroups() {
    final a = me;
    if (a == null) return <Group>[];
    return groups
        .where((g) => !g.isPrivate && !g.members.contains(a.id))
        .toList();
  }

  Group? createGroup(
    String name,
    String description,
    bool isPrivate,
    int gradient, {
    bool isPage = false,
    String category = '',
  }) {
    final a = me;
    if (a == null || denyIfOffline()) return null;
    final cleanName = name.trim();
    final cleanDesc = description.trim();
    final effPrivate = isPage ? false : isPrivate;
    final g = Group(
      id: newId('g'),
      name: cleanName,
      description: cleanDesc,
      ownerId: a.id,
      isPrivate: effPrivate,
      gradient: gradient,
      created: DateTime.now(),
      isPage: isPage,
      category: category,
    );
    g.members.add(a.id);
    g.admins.add(a.id);
    groups.insert(0, g);
    notifyListeners();
    unawaited(
      _db
          .from('groups')
          .insert({
            'name': cleanName,
            'description': cleanDesc,
            'owner_id': a.id,
            'is_private': effPrivate,
            'is_page': isPage,
            'category': category,
            'gradient': gradient,
          })
          .select()
          .then((rows) {
            if (rows.isNotEmpty) {
              final gid = (rows.first['id'] ?? '').toString();
              if (gid.isNotEmpty) {
                final idx = groups.indexOf(g);
                if (idx != -1) {
                  final updated =
                      Group(
                          id: gid,
                          name: g.name,
                          description: g.description,
                          ownerId: g.ownerId,
                          isPrivate: g.isPrivate,
                          gradient: g.gradient,
                          created: g.created,
                          isPage: g.isPage,
                          category: g.category,
                        )
                        ..members.addAll(g.members)
                        ..admins.addAll(g.admins);
                  groups[idx] = updated;
                  notifyListeners();
                }
                unawaited(
                  _db.from('group_members').upsert({
                    'group_id': gid,
                    'user_id': a.id,
                    'is_admin': true,
                  }, onConflict: 'group_id,user_id'),
                );
              }
            }
          }),
    );
    return g;
  }

  bool joinGroup(Group g) {
    final a = me;
    if (a == null || denyIfOffline()) return false;
    if (g.isPrivate || g.members.contains(a.id)) return false;
    g.members.add(a.id);
    notifyListeners();
    if (g.id.length > 10) {
      unawaited(
        _db.from('group_members').upsert({
          'group_id': g.id,
          'user_id': a.id,
          'is_admin': false,
        }, onConflict: 'group_id,user_id'),
      );
    }
    return true;
  }

  bool leaveGroup(Group g) {
    final a = me;
    if (a == null || denyIfOffline() || g.ownerId == a.id) return false;
    g.members.remove(a.id);
    g.admins.remove(a.id);
    notifyListeners();
    if (g.id.length > 10) {
      unawaited(
        _db
            .from('group_members')
            .delete()
            .eq('group_id', g.id)
            .eq('user_id', a.id),
      );
    }
    return true;
  }

  void deleteGroup(Group g) {
    final a = me;
    if (a == null || g.ownerId != a.id || denyIfOffline()) return;
    posts.removeWhere((p) => p.groupId == g.id);
    groups.remove(g);
    notifyListeners();
    if (g.id.length > 10) {
      unawaited(_db.from('groups').delete().eq('id', g.id));
    }
  }

  List<Account> candidatesFor(Group g) {
    final a = me;
    if (a == null) return <Account>[];
    return _byId.values
        .where(
          (o) =>
              o.id != a.id &&
              o.onboarded &&
              !g.members.contains(o.id) &&
              !blockedBetween(a, o),
        )
        .toList();
  }

  bool addMember(Group g, Account acc) {
    final a = me;
    if (a == null || !g.admins.contains(a.id) || denyIfOffline()) return false;
    if (g.members.contains(acc.id) || blockedBetween(a, acc)) return false;
    g.members.add(acc.id);
    _push(
      acc,
      NotifType.group,
      g.isPage
          ? '${a.name} أضافك لمتابعة صفحة ${g.name}'
          : '${a.name} أضافك إلى مجموعة ${g.name}',
    );
    notifyListeners();
    if (g.id.length > 10) {
      unawaited(
        _db.from('group_members').upsert({
          'group_id': g.id,
          'user_id': acc.id,
          'is_admin': false,
        }, onConflict: 'group_id,user_id'),
      );
    }
    return true;
  }

  bool removeMember(Group g, Account acc) {
    final a = me;
    if (a == null || !g.admins.contains(a.id) || denyIfOffline()) return false;
    if (acc.id == g.ownerId) return false;
    g.members.remove(acc.id);
    g.admins.remove(acc.id);
    _push(acc, NotifType.group, 'تمت إزالتك من ${g.name}');
    notifyListeners();
    if (g.id.length > 10) {
      unawaited(
        _db
            .from('group_members')
            .delete()
            .eq('group_id', g.id)
            .eq('user_id', acc.id),
      );
    }
    return true;
  }

  void toggleAdmin(Group g, Account acc) {
    final a = me;
    if (a == null || g.ownerId != a.id || denyIfOffline()) return;
    if (acc.id == g.ownerId) return;
    final nowAdmin = g.admins.add(acc.id);
    if (!nowAdmin) g.admins.remove(acc.id);
    notifyListeners();
    if (g.id.length > 10) {
      unawaited(
        _db
            .from('group_members')
            .update({'is_admin': nowAdmin})
            .eq('group_id', g.id)
            .eq('user_id', acc.id),
      );
    }
  }

  // ───── المراسلة والمكالمات
  bool canMessage(Account other) {
    final a = me;
    if (a == null || a.id == other.id) return false;
    if (blockedBetween(a, other)) return false;
    if (other.whoCanMessage == Audience.everyone) return true;
    if (other.whoCanMessage == Audience.friends) {
      return other.friends.contains(a.id);
    }
    return false;
  }

  List<ChatMessage> chatWith(Account other) {
    final a = me;
    if (a == null) return <ChatMessage>[];
    return messages
        .where(
          (m) =>
              (m.fromId == a.id && m.toId == other.id) ||
              (m.fromId == other.id && m.toId == a.id),
        )
        .toList();
  }

  bool sendMessage(Account to, String text, {Attachment? attachment}) {
    final a = me;
    if (a == null) return false;
    if (text.trim().isEmpty && attachment == null) return false;
    if (denyIfOffline()) return false;
    if (!canMessage(to)) {
      notice('لا يمكنك مراسلة ${to.name}');
      return false;
    }
    final clean = text.trim();
    final msg = ChatMessage(
      id: newId('m'),
      fromId: a.id,
      toId: to.id,
      text: clean,
      created: DateTime.now(),
      attachment: attachment,
    );
    messages.add(msg);
    notifyListeners();
    if (clean.isNotEmpty) {
      unawaited(
        _db
            .from('messages')
            .insert({
              'sender_id': a.id,
              'receiver_id': to.id,
              'text': clean,
              'is_read': false,
            })
            .select()
            .then((rows) {
              if (rows.isNotEmpty) {
                final mid = (rows.first['id'] ?? '').toString();
                if (mid.isNotEmpty) {
                  final idx = messages.indexOf(msg);
                  if (idx != -1) {
                    messages[idx] = ChatMessage(
                      id: mid,
                      fromId: msg.fromId,
                      toId: msg.toId,
                      text: msg.text,
                      created: msg.created,
                      attachment: msg.attachment,
                      callLabel: msg.callLabel,
                      callVideo: msg.callVideo,
                      read: msg.read,
                    );
                    notifyListeners();
                  }
                }
              }
            }),
      );
    }
    return true;
  }

  void markChatRead(Account other) {
    final a = me;
    if (a == null) return;
    var changed = false;
    for (final m in messages) {
      if (m.fromId == other.id && m.toId == a.id && !m.read) {
        m.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
    unawaited(
      _db
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', other.id)
          .eq('receiver_id', a.id),
    );
  }

  void logCall(Account other, {required bool video, required int seconds}) {
    final a = me;
    if (a == null) return;
    final kind = video ? 'مكالمة فيديو' : 'مكالمة صوتية';
    final m = ChatMessage(
      id: newId('m'),
      fromId: a.id,
      toId: other.id,
      text: '',
      created: DateTime.now(),
      callLabel: seconds > 0
          ? '$kind • ${fmtDuration(seconds)}'
          : '$kind • لم يتم الرد',
      callVideo: video,
    );
    m.read = true;
    messages.add(m);
    notifyListeners();
  }

  List<Conversation> conversations() {
    final a = me;
    if (a == null) return <Conversation>[];
    final last = <String, ChatMessage>{};
    final unread = <String, int>{};
    for (final m in messages) {
      String? other;
      if (m.fromId == a.id) {
        other = m.toId;
      } else if (m.toId == a.id) {
        other = m.fromId;
      }
      if (other == null) continue;
      last[other] = m;
      if (m.toId == a.id && !m.read) {
        unread[other] = (unread[other] ?? 0) + 1;
      }
    }
    final out = <Conversation>[];
    for (final e in last.entries) {
      final acc = _byId[e.key];
      if (acc == null) continue;
      out.add(
        Conversation(other: acc, last: e.value, unread: unread[e.key] ?? 0),
      );
    }
    out.sort((x, y) => y.last.created.compareTo(x.last.created));
    return out;
  }

  int get unreadMessages {
    final a = me;
    if (a == null) return 0;
    return messages.where((m) => m.toId == a.id && !m.read).length;
  }
}

class PasswordStrength {
  final int score;
  final bool isEmpty;
  final bool hasLength;
  final bool hasCase;
  final bool hasDigit;
  final bool hasSymbol;

  const PasswordStrength._({
    required this.score,
    required this.isEmpty,
    required this.hasLength,
    required this.hasCase,
    required this.hasDigit,
    required this.hasSymbol,
  });

  factory PasswordStrength.evaluate(String p) {
    final len = p.length >= 8;
    final cs = RegExp(r'[a-z]').hasMatch(p) && RegExp(r'[A-Z]').hasMatch(p);
    final dg = RegExp(r'\d').hasMatch(p);
    final sy = RegExp(r'[^A-Za-z0-9]').hasMatch(p);
    final score = [len, cs, dg, sy].where((e) => e).length;
    return PasswordStrength._(
      score: score,
      isEmpty: p.isEmpty,
      hasLength: len,
      hasCase: cs,
      hasDigit: dg,
      hasSymbol: sy,
    );
  }

  String get label {
    if (isEmpty) return 'أدخل كلمة سر';
    switch (score) {
      case 0:
      case 1:
        return 'ضعيفة';
      case 2:
        return 'متوسطة';
      case 3:
        return 'جيدة';
      default:
        return 'قوية';
    }
  }

  Color get color {
    if (isEmpty) return AppColors.textDim;
    switch (score) {
      case 0:
      case 1:
        return AppColors.danger;
      case 2:
        return const Color(0xFFFFA94D);
      case 3:
        return const Color(0xFFFFD43B);
      default:
        return AppColors.success;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  عناصر مشتركة
// ─────────────────────────────────────────────────────────────────────────────

class AvatarView extends StatelessWidget {
  final String name;
  final int gradient;
  final String emoji;
  final double size;

  const AvatarView({
    super.key,
    required this.name,
    required this.gradient,
    required this.emoji,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '؟'
        : String.fromCharCode(trimmed.runes.first);
    final hasEmoji = emoji.isNotEmpty;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradientOf(gradient),
      ),
      child: Text(
        hasEmoji ? emoji : initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: hasEmoji ? size * 0.5 : size * 0.42,
        ),
      ),
    );
  }
}

Widget avatarOf(Account a, double size) =>
    AvatarView(name: a.name, gradient: a.gradient, emoji: a.emoji, size: size);

class AvatarPicker extends StatelessWidget {
  final String name;
  final int gradient;
  final String emoji;
  final void Function(int gradient, String emoji) onChanged;

  const AvatarPicker({
    super.key,
    required this.name,
    required this.gradient,
    required this.emoji,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cyan, width: 2),
          ),
          child: AvatarView(
            name: name,
            gradient: gradient,
            emoji: emoji,
            size: 96,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'اختر لون صورتك',
          style: TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < kGradients.length; i++)
              GestureDetector(
                onTap: () => onChanged(i, emoji),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradientOf(i),
                    border: Border.all(
                      color: i == gradient ? AppColors.ink : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'اختر رمزاً أو استخدم الحرف الأول',
          style: TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            GestureDetector(
              onTap: () => onChanged(gradient, ''),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: emoji.isEmpty ? AppColors.cyan : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: const Text(
                  'Aa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            for (final e in kAvatarEmojis)
              GestureDetector(
                onTap: () => onChanged(gradient, e),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: e == emoji ? AppColors.cyan : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brand,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: alpha(AppColors.cyan, 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final String? badge;
  const SectionTitle(this.text, {super.key, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 38, color: AppColors.textDim),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class FriendActionButton extends StatelessWidget {
  final AppStore store;
  final Account other;
  const FriendActionButton({
    super.key,
    required this.store,
    required this.other,
  });

  @override
  Widget build(BuildContext context) {
    switch (store.stateWith(other)) {
      case FriendState.friends:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: alpha(AppColors.success, 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 16, color: AppColors.success),
              SizedBox(width: 4),
              Text(
                'أصدقاء',
                style: TextStyle(color: AppColors.success, fontSize: 13),
              ),
            ],
          ),
        );
      case FriendState.incoming:
        return FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 36),
          ),
          onPressed: () {
            if (store.accept(other)) {
              showMsg(context, 'أصبحت الآن صديقاً لـ ${other.name} 🤝');
            }
          },
          child: const Text('قبول الطلب'),
        );
      case FriendState.outgoing:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            minimumSize: const Size(0, 36),
            side: BorderSide(color: alpha(AppColors.ink, 0.2)),
          ),
          onPressed: () => store.cancelRequest(other),
          child: const Text('إلغاء الطلب'),
        );
      case FriendState.none:
        if (!other.allowRequests) {
          return const Text(
            'لا يستقبل طلبات',
            style: TextStyle(color: AppColors.textDim, fontSize: 12.5),
          );
        }
        return FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 36),
          ),
          onPressed: () {
            if (store.sendRequest(other)) {
              showMsg(context, 'تم إرسال طلب صداقة إلى ${other.name}');
            }
          },
          icon: const Icon(Icons.person_add_alt_1, size: 16),
          label: const Text('إضافة'),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  التطبيق الجذر
// ─────────────────────────────────────────────────────────────────────────────

class SocialVerseApp extends StatefulWidget {
  const SocialVerseApp({super.key});

  @override
  State<SocialVerseApp> createState() => _SocialVerseAppState();
}

class _SocialVerseAppState extends State<SocialVerseApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late final AppStore _store = AppStore(notice: _showNotice);

  void _showNotice(String msg) {
    final m = _messengerKey.currentState;
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ),
    );
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      title: 'فلاتر سوشيال',
      theme: buildTheme(),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: const TextScaler.linear(1.08)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final me = _store.me;
          final Widget page;
          if (me == null) {
            page = AuthScreen(key: const ValueKey('auth'), store: _store);
          } else if (!me.onboarded) {
            page = OnboardingScreen(
              key: ValueKey('onboarding-${me.id}'),
              store: _store,
            );
          } else {
            page = HomeShell(key: ValueKey('home-${me.id}'), store: _store);
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: page,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  شاشة تسجيل الدخول / إنشاء الحساب
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  final AppStore store;
  const AuthScreen({super.key, required this.store});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  String? _error;

  PasswordStrength get _strength => PasswordStrength.evaluate(_passCtrl.text);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || _googleLoading) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final err = _isLogin
        ? await widget.store.logInAsync(_emailCtrl.text, _passCtrl.text)
        : await widget.store.signUpAsync(_emailCtrl.text, _passCtrl.text);
    if (err != null && mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    if (_loading || _googleLoading) return;
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _googleLoading = false);
    widget.store.googleDemo();
  }

  @override
  Widget build(BuildContext context) {
    final strength = _strength;
    return Scaffold(
      body: BubbleBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: alpha(AppColors.surface, 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: alpha(AppColors.ink, 0.07)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          alignment: Alignment.topCenter,
                          curve: Curves.easeOut,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildModeSwitch(),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoration: inputDeco(
                                  'البريد الإلكتروني',
                                  Icons.alternate_email,
                                ),
                                validator: (v) {
                                  final t = (v ?? '').trim();
                                  final ok = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(t);
                                  return ok ? null : 'بريد إلكتروني غير صالح';
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                textInputAction: _isLogin
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (_) => setState(() {}),
                                onFieldSubmitted: (_) {
                                  if (_isLogin) _submit();
                                },
                                decoration: inputDeco(
                                  'كلمة السر',
                                  Icons.lock_outline,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.textDim,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) {
                                  final t = v ?? '';
                                  if (t.isEmpty) return 'أدخل كلمة السر';
                                  if (_isLogin) {
                                    return t.length < 6
                                        ? 'كلمة السر قصيرة جداً'
                                        : null;
                                  }
                                  return PasswordStrength.evaluate(t).score < 3
                                      ? 'كلمة السر ضعيفة، حقّق الشروط أدناه'
                                      : null;
                                },
                              ),
                              if (!_isLogin) ...[
                                const SizedBox(height: 12),
                                _buildStrengthMeter(strength),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _confirmCtrl,
                                  obscureText: _obscure,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: inputDeco(
                                    'تأكيد كلمة السر',
                                    Icons.verified_user_outlined,
                                  ),
                                  validator: (v) => v != _passCtrl.text
                                      ? 'كلمتا السر غير متطابقتين'
                                      : null,
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: alpha(AppColors.danger, 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: alpha(AppColors.danger, 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 18,
                                        color: AppColors.danger,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: AppColors.danger,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              GradientButton(
                                label: _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                                icon: _isLogin
                                    ? Icons.login_rounded
                                    : Icons.person_add_alt_1_rounded,
                                loading: _loading,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 18),
                              _buildDivider(),
                              const SizedBox(height: 18),
                              _buildGoogleButton(),
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
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brand,
            boxShadow: [
              BoxShadow(
                color: alpha(AppColors.cyan, 0.4),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.hub_rounded, size: 42, color: Colors.white),
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (rect) => AppColors.brand.createShader(rect),
          child: const Text(
            'SocialVerse',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'فلاتر سوشيال • XUS',
          style: TextStyle(color: AppColors.textDim, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildModeSwitch() {
    Widget tab(String text, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.brand : null,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.textDim,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab('تسجيل الدخول', _isLogin, () {
            setState(() {
              _isLogin = true;
              _error = null;
            });
          }),
          tab('حساب جديد', !_isLogin, () {
            setState(() {
              _isLogin = false;
              _error = null;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildStrengthMeter(PasswordStrength s) {
    Widget rule(bool ok, String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 15,
              color: ok ? AppColors.success : AppColors.textDim,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: ok ? AppColors.ink : AppColors.textDim,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  margin: EdgeInsetsDirectional.only(end: i < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i < s.score ? s.color : AppColors.surface2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'قوة كلمة السر: ',
              style: TextStyle(fontSize: 12.5, color: AppColors.textDim),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: s.color,
              ),
              child: Text(s.label),
            ),
          ],
        ),
        const SizedBox(height: 4),
        rule(s.hasLength, '8 أحرف على الأقل'),
        rule(s.hasCase, 'حروف كبيرة وصغيرة (A-z)'),
        rule(s.hasDigit, 'رقم واحد على الأقل'),
        rule(s.hasSymbol, 'رمز خاص (! @ # \$ ...)'),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: alpha(AppColors.ink, 0.1))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('أو', style: TextStyle(color: AppColors.textDim)),
        ),
        Expanded(child: Divider(color: alpha(AppColors.ink, 0.1))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: alpha(AppColors.ink, 0.3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _google,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: _googleLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Color(0xFF4285F4),
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'G',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'المتابعة باستخدام Google',
                        style: TextStyle(
                          color: Color(0xFF1F1F1F),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  شاشة الترحيب بالحساب الجديد: الاسم + الصورة الشخصية
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final AppStore store;
  const OnboardingScreen({super.key, required this.store});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  late int _gradient;
  String _emoji = '';

  @override
  void initState() {
    super.initState();
    _gradient = widget.store.me?.gradient ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.store.completeOnboarding(_nameCtrl.text, _gradient, _emoji);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BubbleBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'أهلاً بك في SocialVerse 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'حسابك جديد، عرّفنا بنفسك لنبدأ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textDim),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: alpha(AppColors.surface, 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: alpha(AppColors.ink, 0.07)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AvatarPicker(
                              name: _nameCtrl.text,
                              gradient: _gradient,
                              emoji: _emoji,
                              onChanged: (g, e) => setState(() {
                                _gradient = g;
                                _emoji = e;
                              }),
                            ),
                            const SizedBox(height: 22),
                            TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                              onFieldSubmitted: (_) => _continue(),
                              decoration: inputDeco(
                                'اسمك كما سيظهر للآخرين',
                                Icons.person_outline,
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                  ? 'أدخل اسماً من حرفين على الأقل'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            GradientButton(
                              label: 'ابدأ الآن',
                              icon: Icons.rocket_launch_outlined,
                              onPressed: _continue,
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: widget.store.logOut,
                              child: const Text(
                                'استخدام حساب آخر',
                                style: TextStyle(color: AppColors.textDim),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  الواجهة الرئيسية
// ─────────────────────────────────────────────────────────────────────────────

class BubbleBackground extends StatefulWidget {
  final Widget child;
  const BubbleBackground({super.key, required this.child});

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 36),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF4FF), Color(0xFFF7FBFF), Color(0xFFE8F7FF)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _BubblePainter(_c.value),
              size: Size.infinite,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Bubble {
  final double x;
  final double y;
  final double r;
  final int speed;
  final double phase;
  final Color color;
  const _Bubble(this.x, this.y, this.r, this.speed, this.phase, this.color);
}

class _BubblePainter extends CustomPainter {
  final double t;
  _BubblePainter(this.t);

  static const List<_Bubble> _bubbles = [
    _Bubble(0.12, 0.10, 70, 1, 0.00, Color(0xFF13B9FD)),
    _Bubble(0.85, 0.16, 46, 2, 0.20, Color(0xFF7F5AF0)),
    _Bubble(0.30, 0.38, 28, 3, 0.55, Color(0xFFF72585)),
    _Bubble(0.75, 0.50, 90, 1, 0.35, Color(0xFF0175C2)),
    _Bubble(0.10, 0.66, 52, 2, 0.75, Color(0xFF16A085)),
    _Bubble(0.55, 0.82, 64, 1, 0.10, Color(0xFFFFC837)),
    _Bubble(0.90, 0.90, 36, 3, 0.45, Color(0xFF13B9FD)),
    _Bubble(0.45, 0.06, 22, 2, 0.90, Color(0xFFFF6B6B)),
    _Bubble(0.20, 0.92, 40, 3, 0.30, Color(0xFF7F5AF0)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _bubbles) {
      final ang = 2 * math.pi * (t * b.speed + b.phase);
      final dx = math.sin(ang) * 34;
      final dy = math.cos(ang * 0.5 + b.phase * 6) * 50;
      final center = Offset(b.x * size.width + dx, b.y * size.height + dy);
      final rect = Rect.fromCircle(center: center, radius: b.r);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [alpha(b.color, 0.32), alpha(b.color, 0.04)],
        ).createShader(rect);
      canvas.drawCircle(center, b.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.t != t;
}

class OfflineBanner extends StatelessWidget {
  final AppStore store;
  const OfflineBanner({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFFFFF3D6),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'لا يوجد اتصال بالإنترنت — وضع القراءة فقط',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => store.setOffline(false),
            child: const Text('إعادة الاتصال'),
          ),
        ],
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final AppStore store;
  const HomeShell({super.key, required this.store});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final me = store.me;
    if (me == null) return const SizedBox.shrink();

    final tabs = <Widget>[
      HomeTab(store: store),
      FriendsTab(store: store),
      GroupsTab(store: store),
      ProfileTab(store: store),
    ];
    final requests = me.incoming.length;
    final unread = store.unreadCount;
    final unreadMsgs = store.unreadMessages;

    Widget topIcon(IconData icon, String tip, int badge, VoidCallback onTap) {
      return Container(
        margin: const EdgeInsetsDirectional.only(end: 8),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: tip,
          icon: Badge(
            isLabelVisible: badge > 0,
            label: Text('$badge'),
            child: Icon(icon, color: AppColors.ink, size: 22),
          ),
          onPressed: onTap,
        ),
      );
    }

    return BubbleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          titleSpacing: 16,
          toolbarHeight: 64,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brand,
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  size: 21,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: ShaderMask(
                    shaderCallback: (r) => AppColors.brand.createShader(r),
                    child: const Text(
                      'SocialVerse',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 25,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            topIcon(
              Icons.search_rounded,
              'بحث',
              0,
              () => _push(SearchScreen(store: store)),
            ),
            topIcon(
              Icons.forum_rounded,
              'المراسلة',
              unreadMsgs,
              () => _push(MessagesScreen(store: store)),
            ),
            topIcon(
              Icons.notifications_rounded,
              'الإشعارات',
              unread,
              () => _push(NotificationsScreen(store: store)),
            ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                if (store.offline) OfflineBanner(store: store),
                Expanded(
                  child: IndexedStack(index: _index, children: tabs),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: alpha(AppColors.ink, 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.blue,
            unselectedItemColor: AppColors.textDim,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text('$requests'),
                  isLabelVisible: requests > 0,
                  child: const Icon(Icons.people_outline_rounded),
                ),
                activeIcon: Badge(
                  label: Text('$requests'),
                  isLabelVisible: requests > 0,
                  child: const Icon(Icons.people_rounded),
                ),
                label: 'الأصدقاء',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups_rounded),
                label: 'المجموعات',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'الملف الشخصي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  تبويب الرئيسية: القصص + النشر + المنشورات
// ─────────────────────────────────────────────────────────────────────────────

class HomeTab extends StatelessWidget {
  final AppStore store;
  const HomeTab({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final me = store.me;
    if (me == null) return const SizedBox.shrink();
    final feed = store.visiblePosts();
    return RefreshIndicator(
      color: AppColors.cyan,
      backgroundColor: AppColors.surface2,
      onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 500)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          StoriesBar(store: store),
          const SizedBox(height: 14),
          CreatePostBox(store: store),
          const SizedBox(height: 14),
          if (feed.isEmpty)
            const EmptyState(
              icon: Icons.article_outlined,
              title: 'لا توجد منشورات بعد',
              subtitle: 'كن أول من ينشر شيئاً هنا ✍️',
            ),
          for (final p in feed)
            PostCard(key: ValueKey(p.id), store: store, post: p),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  القصص
// ─────────────────────────────────────────────────────────────────────────────

class StoriesBar extends StatelessWidget {
  final AppStore store;
  const StoriesBar({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final me = store.me;
    if (me == null) return const SizedBox.shrink();
    final list = store.visibleStories();
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i == 0) return _addTile(context, me);
          return _storyTile(context, list[i - 1], me);
        },
      ),
    );
  }

  Widget _addTile(BuildContext context, Account me) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => AddStoryDialog(store: store),
      ),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: avatarOf(me, 56),
                ),
                PositionedDirectional(
                  bottom: 2,
                  end: 2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: AppColors.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('إضافة قصة', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _storyTile(BuildContext context, Story s, Account me) {
    final author = store.byId(s.authorId);
    if (author == null) return const SizedBox.shrink();
    final mine = author.id == me.id;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoryViewer(story: s, author: author),
        ),
      ),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradientOf(s.gradient),
              ),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bg,
                ),
                child: avatarOf(author, 56),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mine ? 'قصتك' : author.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class AddStoryDialog extends StatefulWidget {
  final AppStore store;
  const AddStoryDialog({super.key, required this.store});

  @override
  State<AddStoryDialog> createState() => _AddStoryDialogState();
}

class _AddStoryDialogState extends State<AddStoryDialog> {
  final _ctrl = TextEditingController();
  int _gradient = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'قصة جديدة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'تظهر لأصدقائك لمدة 24 ساعة',
                style: TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                height: 150,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: gradientOf(_gradient),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _ctrl,
                  builder: (context, v, _) => Text(
                    v.text.isEmpty ? 'اكتب قصتك...' : v.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                maxLength: 80,
                decoration: inputDeco('نص القصة', Icons.edit_outlined),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < kGradients.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => _gradient = i),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: gradientOf(i),
                          border: Border.all(
                            color: i == _gradient
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _ctrl,
                builder: (context, v, _) => GradientButton(
                  label: 'نشر القصة',
                  icon: Icons.send_rounded,
                  onPressed: v.text.trim().isEmpty
                      ? null
                      : () {
                          if (widget.store.addStory(_ctrl.text, _gradient)) {
                            Navigator.of(context).pop();
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryViewer extends StatefulWidget {
  final Story story;
  final Account author;
  const StoryViewer({super.key, required this.story, required this.author});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          Navigator.of(context).maybePop();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          decoration: BoxDecoration(gradient: gradientOf(s.gradient)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _c.value,
                        minHeight: 3.5,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      avatarOf(widget.author, 40),
                      const SizedBox(width: 10),
                      Text(
                        widget.author.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo(s.created),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          s.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            height: 1.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'اضغط في أي مكان للإغلاق',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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

// ─────────────────────────────────────────────────────────────────────────────
//  صندوق النشر (مع اختيار الجمهور)
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostBox extends StatefulWidget {
  final AppStore store;
  final Group? group;
  const CreatePostBox({super.key, required this.store, this.group});

  @override
  State<CreatePostBox> createState() => _CreatePostBoxState();
}

class _CreatePostBoxState extends State<CreatePostBox> {
  final _ctrl = TextEditingController();
  final List<Attachment> _attachments = <Attachment>[];
  String? _linked;
  Audience? _audience;
  Set<String> _listIds = <String>{};
  Set<String> _hidden = <String>{};

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _insertEmoji(String e) {
    _ctrl.text = '${_ctrl.text}$e';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  Widget _sheetTile(BuildContext ctx, String key, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: AppColors.blue),
      title: Text(label),
      onTap: () => Navigator.of(ctx).pop(key),
    );
  }

  Future<void> _attach() async {
    if (widget.store.denyIfOffline()) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _sheetTile(ctx, 'image', Icons.image_outlined, 'صورة'),
            _sheetTile(ctx, 'video', Icons.videocam_outlined, 'فيديو'),
            _sheetTile(
              ctx,
              'document',
              Icons.description_outlined,
              'ملف / مستند',
            ),
            _sheetTile(ctx, 'link', Icons.link_rounded, 'رابط'),
            _sheetTile(
              ctx,
              'post',
              Icons.account_tree_outlined,
              'ربط بمنشور آخر',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'post') {
      final id = await pickPost(context, widget.store);
      if (id != null && mounted) setState(() => _linked = id);
      return;
    }
    final kind = AttachKind.values.firstWhere((k) => k.name == choice);
    final att = await pickAttachment(context, kind, widget.store);
    if (att != null && mounted) setState(() => _attachments.add(att));
  }

  Future<void> _chooseAudience(Audience a) async {
    if (a == Audience.custom) {
      final me = widget.store.me;
      if (me == null) return;
      final picked = await showDialog<Set<String>>(
        context: context,
        builder: (_) => ListsPickerDialog(lists: me.lists, initial: _listIds),
      );
      if (picked == null || !mounted) return;
      setState(() {
        _listIds = picked;
        _audience = a;
      });
      return;
    }
    setState(() => _audience = a);
  }

  Future<void> _chooseHidden() async {
    final me = widget.store.me;
    if (me == null) return;
    final friends = me.friends
        .map(widget.store.byId)
        .whereType<Account>()
        .toList();
    if (friends.isEmpty) {
      showMsg(context, 'لا يوجد أصدقاء لإخفاء المنشور عنهم');
      return;
    }
    final picked = await pickPeople(
      context,
      title: 'إخفاء المنشور عن...',
      candidates: friends,
      initial: _hidden,
    );
    if (picked != null && mounted) setState(() => _hidden = picked);
  }

  void _publish(Audience audience) {
    if (audience == Audience.custom && _listIds.isEmpty) {
      showMsg(context, 'اختر قائمة واحدة على الأقل');
      return;
    }
    final ok = widget.store.addPost(
      _ctrl.text,
      audience,
      attachments: List<Attachment>.of(_attachments),
      groupId: widget.group?.id,
      linkedPostId: _linked,
      listIds: Set<String>.of(_listIds),
      hiddenFrom: Set<String>.of(_hidden),
    );
    if (!ok) return;
    setState(() {
      _ctrl.clear();
      _attachments.clear();
      _linked = null;
      _hidden = <String>{};
    });
    FocusScope.of(context).unfocus();
    showMsg(context, 'تم نشر منشورك 🎉');
  }

  Widget _chip(IconData icon, String text, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: 10,
        end: 4,
        top: 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.blue),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 15, color: AppColors.textDim),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.store.me;
    if (me == null) return const SizedBox.shrink();
    final g = widget.group;
    final audience = _audience ?? me.defaultAudience;
    final firstName = me.name.trim().split(' ').first;
    final isPageGroup = g != null && g.isPage;
    final canPostHere =
        g == null ||
        (g.isPage ? g.admins.contains(me.id) : g.members.contains(me.id));
    if (!canPostHere) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatarOf(me, 44),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: 800,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: g == null
                        ? 'بماذا تفكر يا $firstName؟'
                        : (isPageGroup
                              ? 'انشر على صفحة ${g.name}...'
                              : 'اكتب شيئاً لأعضاء ${g.name}...'),
                    hintStyle: const TextStyle(color: AppColors.textDim),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surface2,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_attachments.isNotEmpty || _linked != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _attachments)
                    _chip(a.kind.icon, a.name, () {
                      setState(() => _attachments.remove(a));
                    }),
                  if (_linked != null)
                    _chip(Icons.account_tree_outlined, 'منشور مرتبط', () {
                      setState(() => _linked = null);
                    }),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final e in const ['😊', '❤️', '🔥'])
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _insertEmoji(e),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _attach,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        size: 17,
                        color: AppColors.blue,
                      ),
                      SizedBox(width: 4),
                      Text('إرفاق', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
              if (g == null)
                PopupMenuButton<Audience>(
                  tooltip: 'من يرى المنشور؟',
                  color: AppColors.surface,
                  onSelected: _chooseAudience,
                  itemBuilder: (_) => <PopupMenuEntry<Audience>>[
                    for (final a in Audience.values)
                      PopupMenuItem<Audience>(
                        value: a,
                        child: Row(
                          children: [
                            Icon(a.icon, size: 18),
                            const SizedBox(width: 8),
                            Text(a.label),
                          ],
                        ),
                      ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(audience.icon, size: 16, color: AppColors.blue),
                        const SizedBox(width: 4),
                        Text(
                          audience == Audience.custom
                              ? 'قوائم (${_listIds.length})'
                              : audience.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
              if (g == null)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _chooseHidden,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _hidden.isEmpty
                          ? AppColors.surface2
                          : alpha(AppColors.danger, 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_off_outlined,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _hidden.isEmpty
                              ? 'إخفاء عن'
                              : 'مخفي عن ${_hidden.length}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _ctrl,
            builder: (context, value, _) {
              final has =
                  value.text.trim().isNotEmpty ||
                  _attachments.isNotEmpty ||
                  _linked != null;
              return GradientButton(
                label: 'نشر',
                icon: Icons.send_rounded,
                onPressed: has ? () => _publish(audience) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  بطاقة المنشور + التفاعلات المتحركة
// ─────────────────────────────────────────────────────────────────────────────

class PostCard extends StatefulWidget {
  final AppStore store;
  final Post post;
  const PostCard({super.key, required this.store, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _pickerOpen = false;

  Post get post => widget.post;
  AppStore get store => widget.store;

  Reaction? get _mine {
    final me = store.me;
    return me == null ? null : post.reactions[me.id];
  }

  void _react(Reaction r) {
    store.react(post, r);
    setState(() => _pickerOpen = false);
    HapticFeedback.selectionClick();
  }

  void _quickLike() {
    final current = _mine;
    _react(current ?? Reaction.like);
  }

  void _openComments(Account author) {
    final me = store.me;
    if (me == null) return;
    if (!author.allowComments && author.id != me.id) {
      showMsg(context, 'التعليقات مغلقة على هذا المنشور');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CommentsSheet(store: store, post: post),
    );
  }

  void _share() {
    if (post.audience != Audience.everyone) {
      showMsg(context, 'لا يمكن مشاركة منشور غير عام');
      return;
    }
    Clipboard.setData(
      ClipboardData(text: 'https://socialverse.app/post/${post.id}'),
    );
    store.share(post);
    showMsg(context, 'تم نسخ رابط المنشور 🔗');
  }

  @override
  Widget build(BuildContext context) {
    final me = store.me;
    final author = store.byId(post.authorId);
    if (me == null || author == null) return const SizedBox.shrink();
    final isMine = author.id == me.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: isMine ? null : () => _openProfile(author),
                  child: avatarOf(author, 42),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: isMine ? null : () => _openProfile(author),
                        child: Text(
                          author.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            timeAgo(post.created),
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            post.audience.icon,
                            size: 12,
                            color: AppColors.textDim,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textDim),
                  color: AppColors.surface2,
                  onSelected: (v) {
                    if (v == 'delete') {
                      store.deletePost(post);
                    } else if (v == 'copy') {
                      Clipboard.setData(ClipboardData(text: post.text));
                      showMsg(context, 'تم نسخ النص');
                    } else if (v == 'block') {
                      confirmBlock(context, store, author);
                    }
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'copy',
                      child: Text('نسخ النص'),
                    ),
                    if (isMine)
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          'حذف المنشور',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    if (!isMine)
                      PopupMenuItem<String>(
                        value: 'block',
                        child: Text(
                          'حظر ${author.name}',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              post.text,
              style: const TextStyle(fontSize: 16.5, height: 1.6),
            ),
          ),
          _attachmentsSection(),
          _summary(),
          Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: alpha(AppColors.ink, 0.07),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            curve: Curves.easeOut,
            child: _pickerOpen
                ? _picker()
                : const SizedBox(width: double.infinity, height: 0),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _quickLike,
                  onLongPress: () => setState(() => _pickerOpen = !_pickerOpen),
                  onSecondaryTap: () =>
                      setState(() => _pickerOpen = !_pickerOpen),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: _likeLabel(),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _actionButton(
                  Icons.chat_bubble_outline_rounded,
                  'تعليق',
                  () => _openComments(author),
                ),
              ),
              Expanded(
                child: _actionButton(Icons.ios_share_rounded, 'مشاركة', _share),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openProfile(Account a) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfileScreen(store: store, accountId: a.id),
      ),
    );
  }

  Widget _attachmentsSection() {
    final linked = post.linkedPostId;
    if (post.attachments.isEmpty && linked == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in post.attachments)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: AttachmentView(attachment: a),
            ),
          if (linked != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: LinkedPostCard(store: store, postId: linked),
            ),
        ],
      ),
    );
  }

  Widget _likeLabel() {
    final m = _mine;
    if (m == null) {
      return const Row(
        key: ValueKey<String>('none'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thumb_up_alt_outlined, size: 20, color: AppColors.textDim),
          SizedBox(width: 6),
          Text(
            'أعجبني',
            style: TextStyle(color: AppColors.textDim, fontSize: 14),
          ),
        ],
      );
    }
    return Row(
      key: ValueKey<String>(m.name),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(m.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 6),
        Text(
          m.label,
          style: TextStyle(
            color: m.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: AppColors.textDim),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: AppColors.textDim, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary() {
    final total = post.total;
    if (total == 0 && post.comments.isEmpty && post.shares == 0) {
      return const SizedBox(height: 8);
    }
    final tops = post.counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topReactions = tops.take(3).map((e) => e.key).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          if (total > 0) ...[
            _emojiStack(topReactions),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$total',
                key: ValueKey<int>(total),
                style: const TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
            ),
          ],
          const Spacer(),
          if (post.comments.isNotEmpty)
            Text(
              '${post.comments.length} تعليق',
              style: const TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
          if (post.shares > 0) ...[
            const SizedBox(width: 10),
            Text(
              '${post.shares} مشاركة',
              style: const TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emojiStack(List<Reaction> list) {
    return SizedBox(
      width: 22.0 + (list.length - 1) * 14.0,
      height: 22,
      child: Stack(
        children: [
          for (var i = 0; i < list.length; i++)
            PositionedDirectional(
              start: i * 14.0,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface2,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Text(
                  list[i].emoji,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _picker() {
    final mine = _mine;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: alpha(AppColors.ink, 0.08)),
          boxShadow: [
            BoxShadow(
              color: alpha(Colors.black, 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < Reaction.values.length; i++)
              _PickerEmoji(
                reaction: Reaction.values[i],
                index: i,
                selected: mine == Reaction.values[i],
                onTap: () => _react(Reaction.values[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickerEmoji extends StatelessWidget {
  final Reaction reaction;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _PickerEmoji({
    required this.reaction,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 70),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Tooltip(
        message: reaction.label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? alpha(reaction.color, 0.25) : null,
            ),
            child: Text(reaction.emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final AppStore store;
  final Post post;
  const CommentsSheet({super.key, required this.store, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    if (widget.store.addComment(widget.post, t)) _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final comments = widget.post.comments;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: alpha(AppColors.ink, 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'التعليقات',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: comments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(28),
                          child: Text(
                            'كن أول من يعلّق 💬',
                            style: TextStyle(color: AppColors.textDim),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: comments.length,
                          itemBuilder: (context, i) {
                            final c = comments[i];
                            final a = widget.store.byId(c.authorId);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (a != null) avatarOf(a, 34),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface2,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a?.name ?? 'مستخدم',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c.text,
                                            style: const TextStyle(height: 1.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'اكتب تعليقاً...',
                            hintStyle: const TextStyle(
                              color: AppColors.textDim,
                            ),
                            filled: true,
                            fillColor: AppColors.surface2,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.brand,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _send,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  تبويب الأصدقاء
// ─────────────────────────────────────────────────────────────────────────────

class FriendsTab extends StatefulWidget {
  final AppStore store;
  const FriendsTab({super.key, required this.store});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  String _query = '';

  void _openProfile(Account a) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PublicProfileScreen(store: widget.store, accountId: a.id),
      ),
    );
  }

  Widget _personRow(Account a, {required Widget trailing, String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration(),
      child: Row(
        children: [
          GestureDetector(onTap: () => _openProfile(a), child: avatarOf(a, 46)),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _openProfile(a),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if ((subtitle ?? a.bio).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle ?? a.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final me = store.me;
    if (me == null) return const SizedBox.shrink();

    final requests = me.incoming.map(store.byId).whereType<Account>().toList();
    final friends = me.friends.map(store.byId).whereType<Account>().toList();
    final q = _query.trim().toLowerCase();
    final all = store.people();
    final people = all
        .where((a) => q.isEmpty || a.name.toLowerCase().contains(q))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        SectionTitle(
          'طلبات الصداقة',
          badge: requests.isEmpty ? null : '${requests.length}',
        ),
        if (requests.isEmpty)
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'لا توجد طلبات صداقة',
          ),
        for (final a in requests)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openProfile(a),
                  child: avatarOf(a, 56),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 38),
                              ),
                              onPressed: () {
                                if (store.accept(a)) {
                                  showMsg(
                                    context,
                                    'أصبحت الآن صديقاً لـ ${a.name} 🤝',
                                  );
                                }
                              },
                              child: const Text('تأكيد'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.ink,
                                minimumSize: const Size(0, 38),
                                side: BorderSide(
                                  color: alpha(AppColors.ink, 0.18),
                                ),
                              ),
                              onPressed: () => store.decline(a),
                              child: const Text('حذف'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SectionTitle('اقتراحات صداقة'),
        if (all.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: inputDeco('ابحث بالاسم', Icons.search_rounded),
            ),
          ),
        if (all.isEmpty)
          const EmptyState(
            icon: Icons.group_add_outlined,
            title: 'لا يوجد مستخدمون آخرون بعد',
            subtitle: 'عندما ينضم أشخاص جدد سيظهرون هنا',
          )
        else if (people.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'لا نتائج مطابقة',
          ),
        for (final a in people)
          _personRow(
            a,
            subtitle: store.mutualCount(a) > 0
                ? '${store.mutualCount(a)} أصدقاء مشتركين'
                : null,
            trailing: FriendActionButton(store: store, other: a),
          ),
        SectionTitle(
          'أصدقائي',
          badge: friends.isEmpty ? null : '${friends.length}',
        ),
        if (friends.isEmpty)
          const EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'لا أصدقاء بعد',
            subtitle: 'أضف أصدقاءك من قائمة الأشخاص أعلاه',
          ),
        for (final a in friends)
          _personRow(
            a,
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: AppColors.textDim),
              color: AppColors.surface2,
              onSelected: (v) {
                if (v == 'view') {
                  _openProfile(a);
                } else if (v == 'remove') {
                  if (store.unfriend(a)) {
                    showMsg(context, 'تم إلغاء الصداقة مع ${a.name}');
                  }
                } else if (v == 'block') {
                  confirmBlock(context, store, a);
                }
              },
              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'view', child: Text('عرض الملف')),
                PopupMenuItem<String>(
                  value: 'remove',
                  child: Text(
                    'إلغاء الصداقة',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'block',
                  child: Text('حظر', style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  تبويب الملف الشخصي
// ─────────────────────────────────────────────────────────────────────────────

class ProfileTab extends StatelessWidget {
  final AppStore store;
  const ProfileTab({super.key, required this.store});

  Future<void> _edit(BuildContext context, Account me) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => EditProfileDialog(store: store),
    );
    if (saved == true && context.mounted) {
      showMsg(context, 'تم حفظ التغييرات ✅');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = store.me;
    if (me == null) return const SizedBox.shrink();
    final myPosts = store.postsOf(me);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 150,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: gradientOf(me.gradient),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  PositionedDirectional(
                    top: -24,
                    end: -10,
                    child: Icon(
                      Icons.hub_rounded,
                      size: 170,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              bottom: -46,
              start: 20,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bg,
                ),
                child: avatarOf(me, 92),
              ),
            ),
          ],
        ),
        const SizedBox(height: 58),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                me.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                me.email,
                style: const TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                me.bio.isEmpty ? 'أضف نبذة عن نفسك من زر التعديل' : me.bio,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
          label: 'تعديل الملف الشخصي',
          icon: Icons.edit_outlined,
          onPressed: () => _edit(context, me),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: alpha(AppColors.ink, 0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrivacyScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.shield_outlined, size: 19),
                label: const Text('الخصوصية والإعدادات'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: alpha(AppColors.danger, 0.6)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: store.logOut,
              child: const Icon(Icons.logout_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: cardDecoration(),
          child: Row(
            children: [
              _stat('${myPosts.length}', 'منشورات'),
              Container(width: 1, height: 30, color: alpha(AppColors.ink, 0.1)),
              _stat('${me.friends.length}', 'أصدقاء'),
            ],
          ),
        ),
        const SectionTitle('منشوراتي'),
        if (myPosts.isEmpty)
          const EmptyState(
            icon: Icons.edit_note_rounded,
            title: 'لم تنشر شيئاً بعد',
            subtitle: 'شارك أفكارك من الصفحة الرئيسية',
          ),
        for (final p in myPosts)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.text, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      timeAgo(p.created),
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(p.audience.icon, size: 13, color: AppColors.textDim),
                    const Spacer(),
                    const Icon(
                      Icons.favorite_border,
                      size: 15,
                      color: AppColors.textDim,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${p.total}',
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  نافذة تعديل الملف الشخصي
// ─────────────────────────────────────────────────────────────────────────────

class EditProfileDialog extends StatefulWidget {
  final AppStore store;
  const EditProfileDialog({super.key, required this.store});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late int _gradient;
  late String _emoji;

  @override
  void initState() {
    super.initState();
    final me = widget.store.me;
    _name = TextEditingController(text: me?.name ?? '');
    _bio = TextEditingController(text: me?.bio ?? '');
    _gradient = me?.gradient ?? 0;
    _emoji = me?.emoji ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!widget.store.updateProfile(_name.text, _bio.text, _gradient, _emoji)) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تعديل الملف الشخصي',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                AvatarPicker(
                  name: _name.text,
                  gradient: _gradient,
                  emoji: _emoji,
                  onChanged: (g, e) => setState(() {
                    _gradient = g;
                    _emoji = e;
                  }),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: inputDeco('الاسم', Icons.person_outline),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'الاسم قصير جداً'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bio,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 120,
                  decoration: inputDeco(
                    'النبذة التعريفية',
                    Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: alpha(AppColors.ink, 0.18)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GradientButton(
                        label: 'حفظ',
                        icon: Icons.check_rounded,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  شاشة إعدادات الخصوصية
// ─────────────────────────────────────────────────────────────────────────────

class PrivacyScreen extends StatelessWidget {
  final AppStore store;
  const PrivacyScreen({super.key, required this.store});

  Widget _card(List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget _switch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textDim, fontSize: 12.5),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.me;
        if (me == null) return const Scaffold();
        return Scaffold(
          appBar: AppBar(title: const Text('الخصوصية والإعدادات')),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _card([
                    const Text(
                      'من يرى منشوراتك الجديدة؟',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'الجمهور الافتراضي عند النشر (يمكنك تغييره لكل منشور)',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<Audience>(
                      showSelectedIcon: false,
                      segments: [
                        for (final a in const [
                          Audience.everyone,
                          Audience.friends,
                          Audience.onlyMe,
                        ])
                          ButtonSegment<Audience>(
                            value: a,
                            label: Text(a.label),
                          ),
                      ],
                      selected: <Audience>{me.defaultAudience},
                      onSelectionChanged: (s) =>
                          store.setDefaultAudience(s.first),
                    ),
                  ]),
                  _card([
                    _switch(
                      'السماح بطلبات الصداقة',
                      'عند الإيقاف لن يتمكن أحد من إضافتك',
                      me.allowRequests,
                      store.setAllowRequests,
                    ),
                    _switch(
                      'إظهار عدد أصدقائي للآخرين',
                      'عند الإيقاف يظهر العدد "مخفي" في ملفك',
                      me.showFriends,
                      store.setShowFriends,
                    ),
                    _switch(
                      'السماح بالتعليقات على منشوراتي',
                      'عند الإيقاف لا يمكن لغيرك التعليق',
                      me.allowComments,
                      store.setAllowComments,
                    ),
                    _switch(
                      'الإشعارات',
                      'تنبيهات طلبات الصداقة',
                      me.notifications,
                      store.setNotifications,
                    ),
                  ]),
                  _card([
                    const Text(
                      'من يمكنه مراسلتي؟',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<Audience>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment<Audience>(
                          value: Audience.everyone,
                          label: Text('الجميع'),
                        ),
                        ButtonSegment<Audience>(
                          value: Audience.friends,
                          label: Text('الأصدقاء'),
                        ),
                        ButtonSegment<Audience>(
                          value: Audience.onlyMe,
                          label: Text('لا أحد'),
                        ),
                      ],
                      selected: <Audience>{me.whoCanMessage},
                      onSelectionChanged: (s) =>
                          store.setWhoCanMessage(s.first),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: BorderSide(color: alpha(AppColors.ink, 0.2)),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FriendListsScreen(store: store),
                        ),
                      ),
                      icon: const Icon(Icons.family_restroom_rounded, size: 19),
                      label: const Text(
                        'قوائم الأصدقاء والعائلة وصلات القرابة',
                      ),
                    ),
                  ]),
                  _card([
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('وضع القراءة فقط'),
                      subtitle: const Text(
                        'محاكاة انقطاع الإنترنت: تصفّح فقط بدون نشر أو تفاعل',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12.5,
                        ),
                      ),
                      value: store.offline,
                      onChanged: store.setOffline,
                    ),
                  ]),
                  _card([
                    const Text(
                      'المستخدمون المحظورون',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (me.blocked.isEmpty)
                      const Text(
                        'لا يوجد مستخدمون محظورون',
                        style: TextStyle(color: AppColors.textDim),
                      ),
                    for (final a
                        in me.blocked.map(store.byId).whereType<Account>())
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            avatarOf(a, 38),
                            const SizedBox(width: 10),
                            Expanded(child: Text(a.name)),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.ink,
                              ),
                              onPressed: () => store.unblock(a),
                              child: const Text('إلغاء الحظر'),
                            ),
                          ],
                        ),
                      ),
                  ]),
                  _card([
                    const Text(
                      'حسابك',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      me.email,
                      style: const TextStyle(color: AppColors.textDim),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ملف شخص آخر
// ─────────────────────────────────────────────────────────────────────────────

class PublicProfileScreen extends StatelessWidget {
  final AppStore store;
  final String accountId;
  const PublicProfileScreen({
    super.key,
    required this.store,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.me;
        final a = store.byId(accountId);
        if (me == null || a == null) return const Scaffold();
        if (me.blocked.contains(a.id)) {
          return Scaffold(
            appBar: AppBar(title: Text(a.name)),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const EmptyState(
                    icon: Icons.block_rounded,
                    title: 'لقد حظرت هذا المستخدم',
                    subtitle: 'لا يمكنكما رؤية محتوى بعضكما',
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => store.unblock(a),
                    child: const Text('إلغاء الحظر'),
                  ),
                ],
              ),
            ),
          );
        }
        if (a.blocked.contains(me.id)) {
          return Scaffold(
            appBar: AppBar(),
            body: const Padding(
              padding: EdgeInsets.all(16),
              child: EmptyState(
                icon: Icons.block_rounded,
                title: 'هذا الملف غير متاح',
              ),
            ),
          );
        }
        final posts = store.postsOf(a);
        final friendsText = (a.showFriends || a.id == me.id)
            ? '${a.friends.length}'
            : 'مخفي';

        return Scaffold(
          appBar: AppBar(
            title: Text(a.name),
            actions: [
              if (a.id != me.id)
                PopupMenuButton<String>(
                  color: AppColors.surface,
                  onSelected: (_) => confirmBlock(context, store, a),
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'block',
                      child: Text(
                        'حظر المستخدم',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: cardDecoration(),
                    child: Column(
                      children: [
                        avatarOf(a, 92),
                        const SizedBox(height: 12),
                        Text(
                          a.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (a.bio.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            a.bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textDim,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (a.id != me.id)
                          FriendActionButton(store: store, other: a),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${posts.length}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'منشورات',
                                    style: TextStyle(
                                      color: AppColors.textDim,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    friendsText,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'أصدقاء',
                                    style: TextStyle(
                                      color: AppColors.textDim,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SectionTitle('المنشورات'),
                  if (posts.isEmpty)
                    const EmptyState(
                      icon: Icons.lock_outline,
                      title: 'لا توجد منشورات لعرضها',
                    ),
                  for (final p in posts)
                    PostCard(
                      key: ValueKey('pp-${p.id}'),
                      store: store,
                      post: p,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  إضافات: الحظر، المرفقات، المجموعات والصفحات
// ─────────────────────────────────────────────────────────────────────────────

Future<void> confirmBlock(
  BuildContext context,
  AppStore store,
  Account other,
) async {
  if (store.denyIfOffline()) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('حظر ${other.name}؟'),
      content: const Text(
        'لن يرى أي منكما منشورات الآخر ولن يستطيع مراسلته، وستُلغى الصداقة وطلباتها. يمكنك إلغاء الحظر لاحقاً من الخصوصية.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('حظر'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    store.block(other);
    showMsg(context, 'تم حظر ${other.name}');
  }
}

class AttachmentView extends StatelessWidget {
  final Attachment attachment;
  const AttachmentView({super.key, required this.attachment});

  Widget _media(BuildContext context, bool video) {
    final a = attachment;
    return GestureDetector(
      onTap: () {
        if (video) {
          showMsg(
            context,
            'معاينة فقط: تشغيل الفيديو الحقيقي يحتاج حزمة video_player',
          );
        } else {
          showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(gradient: gradientOf(a.color)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_rounded,
                          size: 96,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          a.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: gradientOf(a.color),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                video ? Icons.play_circle_fill_rounded : Icons.image_rounded,
                size: 60,
                color: Colors.white.withAlpha(220),
              ),
            ),
            PositionedDirectional(
              bottom: 10,
              start: 12,
              end: 12,
              child: Row(
                children: [
                  Icon(
                    video ? Icons.videocam_rounded : Icons.image_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    sizeText(a.sizeKb),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required IconData trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.brand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(trailing, color: AppColors.textDim, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = attachment;
    if (a.kind == AttachKind.image) return _media(context, false);
    if (a.kind == AttachKind.video) return _media(context, true);
    if (a.kind == AttachKind.document) {
      return _tile(
        icon: Icons.insert_drive_file_rounded,
        title: a.name,
        subtitle: sizeText(a.sizeKb),
        trailing: Icons.download_rounded,
        onTap: () => showMsg(context, 'تم حفظ "${a.name}" (تجريبي)'),
      );
    }
    final url = a.url ?? '';
    return _tile(
      icon: Icons.link_rounded,
      title: a.name,
      subtitle: url,
      trailing: Icons.copy_rounded,
      onTap: () {
        Clipboard.setData(ClipboardData(text: url));
        showMsg(context, 'تم نسخ الرابط');
      },
    );
  }
}

class LinkedPostCard extends StatelessWidget {
  final AppStore store;
  final String postId;
  const LinkedPostCard({super.key, required this.store, required this.postId});

  @override
  Widget build(BuildContext context) {
    final p = store.postById(postId);
    if (p == null || !store.canSeePost(p)) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.link_off_rounded, size: 18, color: AppColors.textDim),
            SizedBox(width: 8),
            Text(
              'المنشور المرتبط غير متاح',
              style: TextStyle(color: AppColors.textDim),
            ),
          ],
        ),
      );
    }
    final au = store.byId(p.authorId);
    final auName = au == null ? '' : au.name;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: alpha(AppColors.blue, 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 18,
            color: AppColors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرتبط بمنشور $auName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.text.isEmpty ? '(مرفقات)' : p.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<Attachment?> pickAttachment(
  BuildContext context,
  AttachKind kind,
  AppStore store,
) {
  if (kind == AttachKind.link) {
    return showDialog<Attachment>(
      context: context,
      builder: (_) => AddLinkDialog(store: store),
    );
  }
  return showDialog<Attachment>(
    context: context,
    builder: (_) => DemoFileDialog(kind: kind, store: store),
  );
}

class AddLinkDialog extends StatefulWidget {
  final AppStore store;
  const AddLinkDialog({super.key, required this.store});

  @override
  State<AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<AddLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _title = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    super.dispose();
  }

  void _add() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final url = _url.text.trim();
    final host = Uri.tryParse(url)?.host ?? url;
    final title = _title.text.trim();
    Navigator.of(context).pop(
      Attachment(
        id: widget.store.newId('a'),
        kind: AttachKind.link,
        name: title.isEmpty ? (host.isEmpty ? url : host) : title,
        url: url,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('إضافة رابط'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: inputDeco(
                'الرابط',
                Icons.link_rounded,
                hint: 'https://',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                return (t.startsWith('http://') || t.startsWith('https://')) &&
                        t.length > 10
                    ? null
                    : 'أدخل رابطاً يبدأ بـ http:// أو https://';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: inputDeco('عنوان (اختياري)', Icons.title_rounded),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _add, child: const Text('إضافة')),
      ],
    );
  }
}

class DemoFileDialog extends StatefulWidget {
  final AttachKind kind;
  final AppStore store;
  const DemoFileDialog({super.key, required this.kind, required this.store});

  @override
  State<DemoFileDialog> createState() => _DemoFileDialogState();
}

class _DemoFileDialogState extends State<DemoFileDialog> {
  late final TextEditingController _name;
  int _color = 0;

  @override
  void initState() {
    super.initState();
    final k = widget.kind;
    _name = TextEditingController(
      text: k == AttachKind.image
          ? 'صورة-1.jpg'
          : (k == AttachKind.video ? 'فيديو-1.mp4' : 'مستند-1.pdf'),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _add() {
    final n = _name.text.trim();
    if (n.isEmpty) return;
    Navigator.of(context).pop(
      Attachment(
        id: widget.store.newId('a'),
        kind: widget.kind,
        name: n,
        sizeKb: 120 + n.length * 37,
        color: _color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media =
        widget.kind == AttachKind.image || widget.kind == AttachKind.video;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('إرفاق ${widget.kind.label}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'نسخة تجريبية: اختيار ملف حقيقي من جهازك يحتاج حزمة file_picker / image_picker. هنا تُنشأ بطاقة مرفق باسم تكتبه.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF92400E)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: inputDeco('اسم الملف', widget.kind.icon),
            ),
            if (media) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  for (var i = 0; i < kGradients.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => _color = i),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: gradientOf(i),
                          border: Border.all(
                            color: i == _color
                                ? AppColors.ink
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _add, child: const Text('إرفاق')),
      ],
    );
  }
}

Future<String?> pickPost(BuildContext context, AppStore store) {
  return showDialog<String>(
    context: context,
    builder: (_) {
      final list = store.visiblePosts().take(20).toList();
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('اختر منشوراً للربط'),
        content: SizedBox(
          width: double.maxFinite,
          child: list.isEmpty
              ? const Text('لا توجد منشورات متاحة للربط')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final p = list[i];
                    final au = store.byId(p.authorId);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: au == null ? null : avatarOf(au, 36),
                      title: Text(au?.name ?? ''),
                      subtitle: Text(
                        p.text.isEmpty ? '(مرفقات)' : p.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(ctx).pop(p.id),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      );
    },
  );
}

Future<Set<String>?> pickPeople(
  BuildContext context, {
  required String title,
  required List<Account> candidates,
  required Set<String> initial,
}) {
  return showDialog<Set<String>>(
    context: context,
    builder: (_) => PeoplePickerDialog(
      title: title,
      candidates: candidates,
      initial: initial,
    ),
  );
}

class PeoplePickerDialog extends StatefulWidget {
  final String title;
  final List<Account> candidates;
  final Set<String> initial;
  const PeoplePickerDialog({
    super.key,
    required this.title,
    required this.candidates,
    required this.initial,
  });

  @override
  State<PeoplePickerDialog> createState() => _PeoplePickerDialogState();
}

class _PeoplePickerDialogState extends State<PeoplePickerDialog> {
  late final Set<String> _sel = Set<String>.of(widget.initial);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.candidates.isEmpty
            ? const Text('لا يوجد أشخاص')
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final a in widget.candidates)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.trailing,
                      secondary: avatarOf(a, 38),
                      title: Text(a.name),
                      value: _sel.contains(a.id),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _sel.add(a.id);
                        } else {
                          _sel.remove(a.id);
                        }
                      }),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_sel),
          child: const Text('تم'),
        ),
      ],
    );
  }
}

class ListsPickerDialog extends StatefulWidget {
  final List<FriendList> lists;
  final Set<String> initial;
  const ListsPickerDialog({
    super.key,
    required this.lists,
    required this.initial,
  });

  @override
  State<ListsPickerDialog> createState() => _ListsPickerDialogState();
}

class _ListsPickerDialogState extends State<ListsPickerDialog> {
  late final Set<String> _sel = Set<String>.of(widget.initial);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('من يرى المنشور؟ اختر قوائم'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final l in widget.lists)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.trailing,
                secondary: Text(l.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(l.name),
                subtitle: Text('${l.members.length} شخص'),
                value: _sel.contains(l.id),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _sel.add(l.id);
                  } else {
                    _sel.remove(l.id);
                  }
                }),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_sel),
          child: const Text('تم'),
        ),
      ],
    );
  }
}

class GroupAvatar extends StatelessWidget {
  final Group group;
  final double size;
  const GroupAvatar({super.key, required this.group, this.size = 54});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradientOf(group.gradient),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        group.isPage ? Icons.flag_rounded : Icons.groups_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

class GroupsTab extends StatelessWidget {
  final AppStore store;
  const GroupsTab({super.key, required this.store});

  Future<void> _create(BuildContext context, bool isPage) async {
    if (store.denyIfOffline()) return;
    final g = await showDialog<Group>(
      context: context,
      builder: (_) => CreateGroupDialog(store: store, isPage: isPage),
    );
    if (g != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GroupScreen(store: store, groupId: g.id),
        ),
      );
    }
  }

  Widget _card(BuildContext context, Group g, {Widget? trailing}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GroupScreen(store: store, groupId: g.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: cardDecoration(),
        child: Row(
          children: [
            GroupAvatar(group: g),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${g.typeLabel} • ${g.countLabel}',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = store.me;
    if (me == null) return const SizedBox.shrink();
    final mine = store.myGroups();
    final discover = store.discoverGroups();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: GradientButton(
                label: 'إنشاء مجموعة',
                icon: Icons.group_add_rounded,
                onPressed: () => _create(context, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: alpha(AppColors.ink, 0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _create(context, true),
                icon: const Icon(Icons.flag_rounded, size: 18),
                label: const Text('إنشاء صفحة'),
              ),
            ),
          ],
        ),
        SectionTitle(
          'مجموعاتي وصفحاتي',
          badge: mine.isEmpty ? null : '${mine.length}',
        ),
        if (mine.isEmpty)
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'لا توجد مجموعات أو صفحات بعد',
            subtitle: 'أنشئ مجموعة لزملائك أو عائلتك، أو صفحة لمشروعك',
          ),
        for (final g in mine) _card(context, g),
        const SectionTitle('اكتشف'),
        if (discover.isEmpty)
          const EmptyState(
            icon: Icons.explore_outlined,
            title: 'لا توجد مجموعات عامة للانضمام',
          ),
        for (final g in discover)
          _card(
            context,
            g,
            trailing: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
              ),
              onPressed: () {
                if (store.joinGroup(g)) {
                  showMsg(
                    context,
                    g.isPage ? 'أصبحت تتابع ${g.name}' : 'انضممت إلى ${g.name}',
                  );
                }
              },
              child: Text(g.isPage ? 'متابعة' : 'انضمام'),
            ),
          ),
      ],
    );
  }
}

class CreateGroupDialog extends StatefulWidget {
  final AppStore store;
  final bool isPage;
  const CreateGroupDialog({
    super.key,
    required this.store,
    required this.isPage,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  bool _private = false;
  int _gradient = 0;
  String _category = 'مجتمع';

  static const List<String> _categories = [
    'مجتمع',
    'أعمال',
    'فنون',
    'تعليم',
    'تقنية',
    'رياضة',
    'أخرى',
  ];

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _create() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final g = widget.store.createGroup(
      _name.text,
      _desc.text,
      _private,
      _gradient,
      isPage: widget.isPage,
      category: widget.isPage ? _category : '',
    );
    if (g != null) Navigator.of(context).pop(g);
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.isPage;
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  page ? 'إنشاء صفحة جديدة' : 'إنشاء مجموعة جديدة',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: inputDeco(
                    page ? 'اسم الصفحة' : 'اسم المجموعة',
                    page ? Icons.flag_outlined : Icons.groups_outlined,
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'الاسم قصير جداً'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: inputDeco('الوصف', Icons.notes_rounded),
                ),
                if (page) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'التصنيف',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in _categories)
                        ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<bool>(value: false, label: Text('عامة')),
                      ButtonSegment<bool>(value: true, label: Text('خاصة')),
                    ],
                    selected: <bool>{_private},
                    onSelectionChanged: (s) =>
                        setState(() => _private = s.first),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _private
                        ? 'الأعضاء فقط يرون المحتوى، ويضيف المشرفون الأعضاء.'
                        : 'يراها الجميع ويمكنهم الانضمام.',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < kGradients.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => _gradient = i),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: gradientOf(i),
                            border: Border.all(
                              color: i == _gradient
                                  ? AppColors.ink
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: alpha(AppColors.ink, 0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GradientButton(
                        label: 'إنشاء',
                        icon: Icons.check_rounded,
                        onPressed: _create,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddMemberDialog extends StatelessWidget {
  final AppStore store;
  final Group group;
  const AddMemberDialog({super.key, required this.store, required this.group});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final list = store.candidatesFor(group);
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(group.isPage ? 'إضافة متابعين' : 'إضافة أعضاء'),
          content: SizedBox(
            width: double.maxFinite,
            child: list.isEmpty
                ? const Text('لا يوجد أشخاص لإضافتهم الآن')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final a in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: avatarOf(a, 40),
                          title: Text(a.name),
                          trailing: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 34),
                            ),
                            onPressed: () {
                              if (store.addMember(group, a)) {
                                showMsg(context, 'تمت إضافة ${a.name}');
                              }
                            },
                            child: const Text('إضافة'),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }
}

class GroupScreen extends StatelessWidget {
  final AppStore store;
  final String groupId;
  const GroupScreen({super.key, required this.store, required this.groupId});

  Future<void> _confirmDelete(BuildContext context, Group g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('حذف ${g.name}؟'),
        content: const Text('سيتم حذف كل منشوراتها نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      store.deleteGroup(g);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.me;
        final g = store.groupById(groupId);
        if (me == null) return const Scaffold();
        if (g == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Padding(
              padding: EdgeInsets.all(16),
              child: EmptyState(
                icon: Icons.groups_outlined,
                title: 'لم تعد موجودة',
              ),
            ),
          );
        }
        final isMember = g.members.contains(me.id);
        final isOwner = g.ownerId == me.id;
        final isAdmin = g.admins.contains(me.id);
        final canView = isMember || !g.isPrivate;
        final members = g.members.map(store.byId).whereType<Account>().toList();
        int rank(Account x) =>
            x.id == g.ownerId ? 0 : (g.admins.contains(x.id) ? 1 : 2);
        members.sort((a, b) {
          final r = rank(a).compareTo(rank(b));
          return r != 0 ? r : a.name.compareTo(b.name);
        });
        final posts = canView ? store.groupPosts(g) : <Post>[];

        return Scaffold(
          appBar: AppBar(
            title: Text(g.name),
            actions: [
              if (isOwner)
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _confirmDelete(context, g),
                )
              else if (isMember)
                IconButton(
                  tooltip: g.isPage ? 'إلغاء المتابعة' : 'مغادرة',
                  icon: const Icon(Icons.exit_to_app_rounded),
                  onPressed: () {
                    if (store.leaveGroup(g)) {
                      showMsg(
                        context,
                        g.isPage ? 'ألغيت المتابعة' : 'غادرت المجموعة',
                      );
                    }
                  },
                ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: cardDecoration(),
                    child: Column(
                      children: [
                        Container(
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: gradientOf(g.gradient),
                          ),
                          child: Center(
                            child: Icon(
                              g.isPage
                                  ? Icons.flag_rounded
                                  : Icons.groups_rounded,
                              size: 58,
                              color: Colors.white.withAlpha(230),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                g.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${g.typeLabel} • ${g.countLabel}',
                                style: const TextStyle(
                                  color: AppColors.textDim,
                                ),
                              ),
                              if (g.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  g.description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(height: 1.5),
                                ),
                              ],
                              const SizedBox(height: 14),
                              if (!isMember && !g.isPrivate)
                                GradientButton(
                                  label: g.isPage ? 'متابعة' : 'انضمام',
                                  icon: Icons.add_rounded,
                                  onPressed: () {
                                    if (store.joinGroup(g)) {
                                      showMsg(
                                        context,
                                        g.isPage
                                            ? 'أصبحت تتابع الصفحة'
                                            : 'انضممت إلى المجموعة',
                                      );
                                    }
                                  },
                                ),
                              if (!isMember && g.isPrivate)
                                const Text(
                                  'مجموعة خاصة: يضيفك أحد المشرفين',
                                  style: TextStyle(color: AppColors.textDim),
                                ),
                              if (isAdmin)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ink,
                                    side: BorderSide(
                                      color: alpha(AppColors.ink, 0.2),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (store.denyIfOffline()) return;
                                    showDialog<void>(
                                      context: context,
                                      builder: (_) => AddMemberDialog(
                                        store: store,
                                        group: g,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    g.isPage ? 'إضافة متابعين' : 'إضافة أعضاء',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canView) ...[
                    SectionTitle(
                      g.isPage ? 'المتابعون' : 'الأعضاء',
                      badge: '${members.length}',
                    ),
                    for (final a in members)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: cardDecoration(),
                        child: Row(
                          children: [
                            avatarOf(a, 42),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.id == me.id ? '${a.name} (أنت)' : a.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (rank(a) < 2)
                                    Text(
                                      rank(a) == 0 ? 'المالك' : 'مشرف',
                                      style: const TextStyle(
                                        color: AppColors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (a.id != me.id)
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: AppColors.textDim,
                                ),
                                color: AppColors.surface,
                                onSelected: (v) {
                                  if (v == 'profile') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => PublicProfileScreen(
                                          store: store,
                                          accountId: a.id,
                                        ),
                                      ),
                                    );
                                  } else if (v == 'remove') {
                                    if (store.removeMember(g, a)) {
                                      showMsg(context, 'تمت إزالة ${a.name}');
                                    }
                                  } else if (v == 'admin') {
                                    store.toggleAdmin(g, a);
                                  }
                                },
                                itemBuilder: (_) => <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'profile',
                                    child: Text('عرض الملف'),
                                  ),
                                  if (isAdmin && a.id != g.ownerId)
                                    const PopupMenuItem<String>(
                                      value: 'remove',
                                      child: Text(
                                        'إزالة',
                                        style: TextStyle(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  if (isOwner)
                                    PopupMenuItem<String>(
                                      value: 'admin',
                                      child: Text(
                                        g.admins.contains(a.id)
                                            ? 'إلغاء الإشراف'
                                            : 'ترقية لمشرف',
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    const SectionTitle('المنشورات'),
                    if (isMember) CreatePostBox(store: store, group: g),
                    if (isMember) const SizedBox(height: 12),
                    if (posts.isEmpty)
                      const EmptyState(
                        icon: Icons.article_outlined,
                        title: 'لا توجد منشورات بعد',
                      ),
                    for (final p in posts)
                      PostCard(
                        key: ValueKey('g-${p.id}'),
                        store: store,
                        post: p,
                      ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: EmptyState(
                        icon: Icons.lock_outline,
                        title: 'هذه مجموعة خاصة',
                        subtitle: 'انضم لترى المحتوى والأعضاء',
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  الإشعارات
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatelessWidget {
  final AppStore store;
  const NotificationsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.me;
        if (me == null) return const Scaffold();
        final list = store.myNotifications();
        final hasUnread = list.any((n) => !n.read);
        return Scaffold(
          appBar: AppBar(
            title: const Text('الإشعارات'),
            actions: [
              if (hasUnread)
                TextButton(
                  onPressed: store.markAllRead,
                  child: const Text('قراءة الكل'),
                ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (!me.notifications)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'الإشعارات الجديدة متوقفة من إعدادات الخصوصية',
                        style: TextStyle(color: Color(0xFF92400E)),
                      ),
                    ),
                  if (list.isEmpty)
                    const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'لا توجد إشعارات',
                      subtitle: 'ستظهر هنا التفاعلات والتعليقات وطلبات الصداقة',
                    ),
                  for (final n in list)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => store.markRead(n),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: n.read
                              ? AppColors.surface
                              : alpha(AppColors.cyan, 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: alpha(AppColors.ink, 0.06)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: alpha(n.type.color, 0.15),
                              ),
                              child: Icon(
                                n.type.icon,
                                color: n.type.color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.text,
                                    style: TextStyle(
                                      fontWeight: n.read
                                          ? FontWeight.w500
                                          : FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    timeAgo(n.created),
                                    style: const TextStyle(
                                      color: AppColors.textDim,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!n.read)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  المراسلة
// ─────────────────────────────────────────────────────────────────────────────

String messagePreview(ChatMessage m, Account me) {
  final prefix = m.fromId == me.id ? 'أنت: ' : '';
  if (m.callLabel != null) return '${m.callVideo ? '📹' : '📞'} ${m.callLabel}';
  if (m.attachment != null) return '$prefix📎 ${m.attachment!.name}';
  return '$prefix${m.text}';
}

class MessagesScreen extends StatelessWidget {
  final AppStore store;
  const MessagesScreen({super.key, required this.store});

  void _open(BuildContext context, Account a) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(store: store, otherId: a.id),
      ),
    );
  }

  Future<void> _newChat(BuildContext context, Account me) async {
    final all = store.people().where(store.canMessage).toList();
    final friends = me.friends
        .map(store.byId)
        .whereType<Account>()
        .where(store.canMessage)
        .toList();
    final list = <Account>[...friends, ...all];
    final picked = await showDialog<Account>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('محادثة جديدة'),
        content: SizedBox(
          width: double.maxFinite,
          child: list.isEmpty
              ? const Text('لا يوجد أشخاص يمكنك مراسلتهم الآن')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final a in list)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: avatarOf(a, 40),
                        title: Text(a.name),
                        subtitle: me.friends.contains(a.id)
                            ? const Text('صديق')
                            : null,
                        onTap: () => Navigator.of(ctx).pop(a),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
    if (picked != null && context.mounted) _open(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.me;
        if (me == null) return const Scaffold();
        final convs = store.conversations();
        return Scaffold(
          appBar: AppBar(title: const Text('المراسلة')),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            onPressed: () => _newChat(context, me),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('محادثة جديدة'),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: [
                  if (convs.isEmpty)
                    const EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'لا توجد محادثات بعد',
                      subtitle: 'ابدأ محادثة مع صديق من زر "محادثة جديدة"',
                    ),
                  for (final c in convs)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _open(context, c.other),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: cardDecoration(),
                        child: Row(
                          children: [
                            avatarOf(c.other, 50),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.other.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    messagePreview(c.last, me),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: c.unread > 0
                                          ? AppColors.ink
                                          : AppColors.textDim,
                                      fontWeight: c.unread > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Text(
                                  timeAgo(c.last.created),
                                  style: const TextStyle(
                                    color: AppColors.textDim,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (c.unread > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${c.unread}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class EmojiPanel extends StatelessWidget {
  final void Function(String emoji) onPick;
  const EmojiPanel({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      color: AppColors.surface,
      child: GridView.count(
        crossAxisCount: 8,
        padding: const EdgeInsets.all(8),
        children: [
          for (final e in kChatEmojis)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onPick(e),
              child: Center(
                child: Text(e, style: const TextStyle(fontSize: 26)),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final AppStore store;
  final String otherId;
  const ChatScreen({super.key, required this.store, required this.otherId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _emoji = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final o = widget.store.byId(widget.otherId);
      if (o != null) widget.store.markChatRead(o);
      _toEnd(animate: false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          max,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(max);
      }
    });
  }

  void _send() {
    final o = widget.store.byId(widget.otherId);
    if (o == null) return;
    if (widget.store.sendMessage(o, _ctrl.text)) {
      _ctrl.clear();
      _toEnd();
    }
  }

  Future<void> _attach(Account o) async {
    if (widget.store.denyIfOffline()) return;
    final kind = await showModalBottomSheet<AttachKind>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final k in AttachKind.values)
              ListTile(
                leading: Icon(k.icon, color: AppColors.blue),
                title: Text(k.label),
                onTap: () => Navigator.of(ctx).pop(k),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (kind == null || !mounted) return;
    final att = await pickAttachment(context, kind, widget.store);
    if (att != null && mounted) {
      if (widget.store.sendMessage(o, '', attachment: att)) _toEnd();
    }
  }

  void _call(Account o, bool video) {
    if (widget.store.denyIfOffline()) return;
    if (!widget.store.canMessage(o)) {
      showMsg(context, 'لا يمكنك الاتصال بـ ${o.name}');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CallScreen(store: widget.store, other: o, video: video),
      ),
    );
  }

  Widget _bubble(ChatMessage m, Account me) {
    final mine = m.fromId == me.id;
    if (m.callLabel != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                m.callVideo ? Icons.videocam_rounded : Icons.call_rounded,
                size: 16,
                color: AppColors.blue,
              ),
              const SizedBox(width: 6),
              Text(m.callLabel!, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: mine ? AppColors.brand : null,
            color: mine ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: mine ? null : Border.all(color: alpha(AppColors.ink, 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.attachment != null) ...[
                AttachmentView(attachment: m.attachment!),
                if (m.text.isNotEmpty) const SizedBox(height: 6),
              ],
              if (m.text.isNotEmpty)
                Text(
                  m.text,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: mine ? Colors.white : AppColors.ink,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                timeAgo(m.created),
                style: TextStyle(
                  fontSize: 10.5,
                  color: mine ? Colors.white70 : AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.me;
        final o = store.byId(widget.otherId);
        if (me == null || o == null) return const Scaffold();
        final msgs = store.chatWith(o);
        final can = store.canMessage(o);
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                avatarOf(o, 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    o.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'مكالمة صوتية',
                icon: const Icon(Icons.call_rounded, color: AppColors.blue),
                onPressed: () => _call(o, false),
              ),
              IconButton(
                tooltip: 'مكالمة فيديو',
                icon: const Icon(Icons.videocam_rounded, color: AppColors.blue),
                onPressed: () => _call(o, true),
              ),
            ],
          ),
          body: Column(
            children: [
              if (store.offline) OfflineBanner(store: store),
              Expanded(
                child: msgs.isEmpty
                    ? const Center(
                        child: Text(
                          'ابدأ المحادثة بإرسال رسالة 👋',
                          style: TextStyle(color: AppColors.textDim),
                        ),
                      )
                    : ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        children: [for (final m in msgs) _bubble(m, me)],
                      ),
              ),
              if (!can)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  color: AppColors.surface,
                  child: const Text(
                    'لا يمكنك مراسلة هذا المستخدم',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDim),
                  ),
                )
              else
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _emoji
                                ? Icons.keyboard_rounded
                                : Icons.emoji_emotions_outlined,
                            color: AppColors.blue,
                          ),
                          onPressed: () => setState(() => _emoji = !_emoji),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.attach_file_rounded,
                            color: AppColors.blue,
                          ),
                          onPressed: () => _attach(o),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            minLines: 1,
                            maxLines: 4,
                            onSubmitted: (_) => _send(),
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'اكتب رسالة...',
                              hintStyle: const TextStyle(
                                color: AppColors.textDim,
                              ),
                              filled: true,
                              fillColor: AppColors.surface2,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.brand,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _send,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_emoji && can)
                EmojiPanel(
                  onPick: (e) {
                    _ctrl.text = '${_ctrl.text}$e';
                    _ctrl.selection = TextSelection.collapsed(
                      offset: _ctrl.text.length,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  المكالمات الصوتية والمرئية
// ─────────────────────────────────────────────────────────────────────────────

class CallScreen extends StatefulWidget {
  final AppStore store;
  final Account other;
  final bool video;
  const CallScreen({
    super.key,
    required this.store,
    required this.other,
    required this.video,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();
  Timer? _ring;
  Timer? _tick;
  bool _connected = false;
  bool _ended = false;
  int _seconds = 0;
  bool _muted = false;
  bool _speaker = false;
  bool _camOff = false;
  int _filter = 0;
  String _sticker = '';

  @override
  void initState() {
    super.initState();
    _ring = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _connected = true);
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    });
  }

  @override
  void dispose() {
    _ring?.cancel();
    _tick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _end() {
    if (_ended) return;
    _ended = true;
    widget.store.logCall(
      widget.other,
      video: widget.video,
      seconds: _connected ? _seconds : 0,
    );
    Navigator.of(context).pop();
  }

  Widget _ctl(IconData icon, bool active, VoidCallback onTap, {Color? bg}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg ?? (active ? Colors.white : Colors.white24),
        ),
        child: Icon(
          icon,
          size: 26,
          color: bg != null
              ? Colors.white
              : (active ? const Color(0xFF0B1D3A) : Colors.white),
        ),
      ),
    );
  }

  Future<void> _pickSticker() async {
    final e = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SizedBox(
        height: 260,
        child: GridView.count(
          crossAxisCount: 6,
          padding: const EdgeInsets.all(12),
          children: [
            InkWell(
              onTap: () => Navigator.of(ctx).pop(''),
              child: const Center(child: Icon(Icons.block_rounded)),
            ),
            for (final s in kChatEmojis)
              InkWell(
                onTap: () => Navigator.of(ctx).pop(s),
                child: Center(
                  child: Text(s, style: const TextStyle(fontSize: 30)),
                ),
              ),
          ],
        ),
      ),
    );
    if (e != null && mounted) setState(() => _sticker = e);
  }

  Widget _selfView() {
    final me = widget.store.me;
    return Container(
      width: 110,
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white54, width: 1.5),
      ),
      child: _camOff
          ? Container(
              color: Colors.black54,
              child: const Center(
                child: Icon(
                  Icons.videocam_off_rounded,
                  color: Colors.white70,
                  size: 34,
                ),
              ),
            )
          : ColorFiltered(
              colorFilter: ColorFilter.matrix(kFilterMatrices[_filter]),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: gradientOf(me?.gradient ?? 0),
                    ),
                    child: Center(
                      child: me == null
                          ? const SizedBox.shrink()
                          : avatarOf(me, 56),
                    ),
                  ),
                  if (_sticker.isNotEmpty)
                    Center(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_sticker),
                        tween: Tween<double>(begin: 0.2, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, v, child) =>
                            Transform.scale(scale: v, child: child),
                        child: Text(
                          _sticker,
                          style: const TextStyle(fontSize: 54),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.other;
    final video = widget.video;
    final status = _connected
        ? fmtDuration(_seconds)
        : (video
              ? 'مكالمة فيديو... جارٍ الاتصال'
              : 'مكالمة صوتية... جارٍ الاتصال');
    return Scaffold(
      backgroundColor: const Color(0xFF0B1D3A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1D3A), Color(0xFF0A4D8C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!_connected)
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, _) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  for (var i = 0; i < 3; i++)
                                    Builder(
                                      builder: (context) {
                                        final t = (_pulse.value + i / 3) % 1.0;
                                        return Container(
                                          width: 130 + 150 * t,
                                          height: 130 + 150 * t,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withAlpha(
                                                ((1 - t) * 110).round(),
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          avatarOf(o, 130),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    if (video && _connected)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'كاميرا الطرف الآخر (محاكاة)',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              if (video)
                PositionedDirectional(top: 16, end: 16, child: _selfView()),
              if (video && _connected)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 110,
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: kFilterNames.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => ChoiceChip(
                        label: Text(kFilterNames[i]),
                        selected: _filter == i,
                        onSelected: (_) => setState(() => _filter = i),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ctl(
                      _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      _muted,
                      () => setState(() => _muted = !_muted),
                    ),
                    const SizedBox(width: 14),
                    _ctl(
                      Icons.volume_up_rounded,
                      _speaker,
                      () => setState(() => _speaker = !_speaker),
                    ),
                    if (video) ...[
                      const SizedBox(width: 14),
                      _ctl(
                        _camOff
                            ? Icons.videocam_off_rounded
                            : Icons.videocam_rounded,
                        _camOff,
                        () => setState(() => _camOff = !_camOff),
                      ),
                      const SizedBox(width: 14),
                      _ctl(
                        Icons.emoji_emotions_rounded,
                        _sticker.isNotEmpty,
                        _pickSticker,
                      ),
                    ],
                    const SizedBox(width: 14),
                    _ctl(
                      Icons.call_end_rounded,
                      false,
                      _end,
                      bg: AppColors.danger,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  قوائم الأصدقاء والعائلة وصلات القرابة
// ─────────────────────────────────────────────────────────────────────────────

class FriendListsScreen extends StatelessWidget {
  final AppStore store;
  const FriendListsScreen({super.key, required this.store});

  Future<void> _newList(BuildContext context) async {
    if (store.denyIfOffline()) return;
    final name = TextEditingController();
    var emoji = kListEmojis.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('قائمة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: inputDeco('اسم القائمة', Icons.list_alt_rounded),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final e in kListEmojis)
                    ChoiceChip(
                      label: Text(e, style: const TextStyle(fontSize: 20)),
                      selected: emoji == e,
                      onSelected: (_) => setS(() => emoji = e),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) store.createList(name.text, emoji);
    name.dispose();
  }

  Future<void> _editMembers(
    BuildContext context,
    Account me,
    FriendList l,
  ) async {
    if (store.denyIfOffline()) return;
    final friends = me.friends.map(store.byId).whereType<Account>().toList();
    final picked = await pickPeople(
      context,
      title: 'أعضاء "${l.name}"',
      candidates: friends,
      initial: l.members,
    );
    if (picked != null) store.setListMembers(l, picked);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.me;
        if (me == null) return const Scaffold();
        final friends = me.friends
            .map(store.byId)
            .whereType<Account>()
            .toList();
        return Scaffold(
          appBar: AppBar(title: const Text('قوائم الأصدقاء والعائلة')),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const Text(
                    'استخدم القوائم لتحديد من يرى منشوراتك: اختر "قوائم محددة" عند النشر.',
                    style: TextStyle(color: AppColors.textDim, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  GradientButton(
                    label: 'قائمة جديدة',
                    icon: Icons.add_rounded,
                    onPressed: () => _newList(context),
                  ),
                  const SectionTitle('قوائمي'),
                  for (final l in me.lists)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: cardDecoration(),
                      child: Row(
                        children: [
                          Text(l.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${l.members.length} شخص',
                                  style: const TextStyle(
                                    color: AppColors.textDim,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: BorderSide(
                                color: alpha(AppColors.ink, 0.2),
                              ),
                            ),
                            onPressed: () => _editMembers(context, me, l),
                            child: const Text('الأعضاء'),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.danger,
                            ),
                            onPressed: () => store.deleteList(l),
                          ),
                        ],
                      ),
                    ),
                  const SectionTitle('صلات القرابة'),
                  if (friends.isEmpty)
                    const EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'أضف أصدقاء أولاً لتحديد صلة القرابة',
                    ),
                  for (final f in friends)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: cardDecoration(),
                      child: Row(
                        children: [
                          avatarOf(f, 42),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              f.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DropdownButton<String>(
                            value: me.relations[f.id] ?? '',
                            dropdownColor: AppColors.surface,
                            underline: const SizedBox.shrink(),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('بدون تحديد'),
                              ),
                              for (final r in kRelations)
                                DropdownMenuItem<String>(
                                  value: r,
                                  child: Text(r),
                                ),
                            ],
                            onChanged: (v) => store.setRelation(f, v),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  البحث
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  final AppStore store;
  const SearchScreen({super.key, required this.store});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.me;
        if (me == null) return const Scaffold();
        final t = _q.trim().toLowerCase();
        final people = t.isEmpty
            ? <Account>[]
            : store._byId.values
                  .where(
                    (a) =>
                        a.id != me.id &&
                        a.onboarded &&
                        !store.blockedBetween(me, a) &&
                        a.name.toLowerCase().contains(t),
                  )
                  .toList();
        final posts = t.isEmpty
            ? <Post>[]
            : store.posts
                  .where(
                    (p) =>
                        store.canSeePost(p) && p.text.toLowerCase().contains(t),
                  )
                  .toList();
        final groups = t.isEmpty
            ? <Group>[]
            : store.groups
                  .where(
                    (g) =>
                        (!g.isPrivate || g.members.contains(me.id)) &&
                        (g.name.toLowerCase().contains(t) ||
                            g.description.toLowerCase().contains(t)),
                  )
                  .toList();

        return Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'ابحث في الأشخاص، المنشورات، المجموعات...',
                border: InputBorder.none,
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _q = '');
                        },
                      ),
              ),
            ),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (t.isEmpty)
                    const EmptyState(
                      icon: Icons.search_rounded,
                      title: 'ابحث عن أي شيء',
                      subtitle: 'أصدقاء، منشورات، مجموعات، أو صفحات',
                    ),
                  if (t.isNotEmpty &&
                      people.isEmpty &&
                      posts.isEmpty &&
                      groups.isEmpty)
                    const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'لا توجد نتائج',
                    ),
                  if (people.isNotEmpty) const SectionTitle('أشخاص'),
                  for (final a in people)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: cardDecoration(),
                      child: Row(
                        children: [
                          avatarOf(a, 44),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PublicProfileScreen(
                                    store: store,
                                    accountId: a.id,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (a.bio.isNotEmpty)
                                    Text(
                                      a.bio,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textDim,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          FriendActionButton(store: store, other: a),
                        ],
                      ),
                    ),
                  if (groups.isNotEmpty) const SectionTitle('مجموعات وصفحات'),
                  for (final g in groups)
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              GroupScreen(store: store, groupId: g.id),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: cardDecoration(),
                        child: Row(
                          children: [
                            GroupAvatar(group: g, size: 46),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${g.typeLabel} • ${g.countLabel}',
                                    style: const TextStyle(
                                      color: AppColors.textDim,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (posts.isNotEmpty) const SectionTitle('منشورات'),
                  for (final p in posts)
                    PostCard(
                      key: ValueKey('sr-${p.id}'),
                      store: store,
                      post: p,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
