// ============================================================================
//  فلاتر سوشيال  |  SocialVerse (XUS)  -  النسخة النظيفة (بدون أي بيانات وهمية)
//  ملف واحد - بدون أي حزم خارجية - يعمل على Chrome والهواتف
//
//  التشغيل:
//    flutter create socialverse
//    استبدل محتوى lib/main.dart بهذا الملف
//    flutter run -d chrome
//
//  النشر على Cloudflare Pages:
//    flutter build web --release
//    ثم ارفع مجلد build/web
//
//  ملاحظة: كل البيانات (الحسابات/المنشورات) تعيش داخل الذاكرة في كلاس AppStore.
//  لربطها بقاعدة بيانات حقيقية (Cloudflare Workers + D1) يكفي استبدال دوال AppStore.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const SocialVerseApp());

// ─────────────────────────────────────────────────────────────────────────────
//  الألوان والثيم
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();
  static const Color bg = Color(0xFF0A0F1A);
  static const Color surface = Color(0xFF121A2B);
  static const Color surface2 = Color(0xFF1B2640);
  static const Color blue = Color(0xFF0175C2);
  static const Color cyan = Color(0xFF13B9FD);
  static const Color textDim = Color(0xFF8FA0BC);
  static const Color danger = Color(0xFFFF5C7A);
  static const Color success = Color(0xFF34D399);
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
  '😎', '🦊', '🐱', '🐼', '🦁', '🚀', '🎨', '🎧', '⚽', '🌸', '🔥', '⭐',
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
      backgroundColor: AppColors.surface2,
    ),
  );
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.cyan,
    onPrimary: Colors.black,
    secondary: AppColors.blue,
    surface: AppColors.surface,
    error: AppColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: Colors.white,
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
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: alpha(Colors.white, 0.05)),
    );

// ─────────────────────────────────────────────────────────────────────────────
//  النماذج (Models)
// ─────────────────────────────────────────────────────────────────────────────

enum Audience {
  everyone('عام', Icons.public),
  friends('الأصدقاء', Icons.group_outlined),
  onlyMe('أنا فقط', Icons.lock_outline);

  final String label;
  final IconData icon;
  const Audience(this.label, this.icon);
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

class Account {
  final String id;
  final String email;
  final String password;

  String name = '';
  String bio = '';
  int gradient = 0;
  String emoji = '';
  bool onboarded = false;

  // إعدادات الخصوصية
  Audience defaultAudience = Audience.everyone;
  bool allowRequests = true;
  bool showFriends = true;
  bool allowComments = true;
  bool notifications = true;

  final Set<String> friends = <String>{};
  final Set<String> incoming = <String>{};
  final Set<String> outgoing = <String>{};

  Account({required this.id, required this.email, required this.password});
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
  int shares = 0;

  Post({
    required this.id,
    required this.authorId,
    required this.created,
    required this.text,
    required this.audience,
  });

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
//  المتجر (AppStore): كل الحسابات والمنشورات - يبدأ فارغاً تماماً
// ─────────────────────────────────────────────────────────────────────────────

class AppStore extends ChangeNotifier {
  final Map<String, Account> _byEmail = <String, Account>{};
  final Map<String, Account> _byId = <String, Account>{};
  final List<Post> posts = <Post>[];
  final List<Story> stories = <Story>[];
  Account? me;
  int _seq = 0;

  Account? byId(String id) => _byId[id];

  // ───── الحسابات
  String? signUp(String email, String password) {
    final key = email.trim().toLowerCase();
    if (_byEmail.containsKey(key)) {
      return 'هذا البريد مسجّل بالفعل، جرّب تسجيل الدخول';
    }
    _seq++;
    final a = Account(id: 'u$_seq', email: key, password: password);
    a.gradient = _seq % kGradients.length;
    _byEmail[key] = a;
    _byId[a.id] = a;
    me = a;
    notifyListeners();
    return null;
  }

  String? logIn(String email, String password) {
    final a = _byEmail[email.trim().toLowerCase()];
    if (a == null) return 'لا يوجد حساب بهذا البريد، أنشئ حساباً جديداً';
    if (a.password != password) return 'كلمة السر غير صحيحة';
    me = a;
    notifyListeners();
    return null;
  }

  /// محاكاة تسجيل Google: في كل مرة ينشئ حساباً جديداً (لاستبدالها بتسجيل حقيقي لاحقاً)
  void googleDemo() {
    var i = _seq + 1;
    var email = 'google.user$i@gmail.com';
    while (_byEmail.containsKey(email)) {
      i++;
      email = 'google.user$i@gmail.com';
    }
    signUp(email, 'google-demo');
  }

  void logOut() {
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
  }

  void updateProfile(String name, String bio, int gradient, String emoji) {
    final a = me;
    if (a == null) return;
    a.name = name.trim();
    a.bio = bio.trim();
    a.gradient = gradient;
    a.emoji = emoji;
    notifyListeners();
  }

  // ───── الخصوصية
  void setDefaultAudience(Audience v) {
    me?.defaultAudience = v;
    notifyListeners();
  }

  void setAllowRequests(bool v) {
    me?.allowRequests = v;
    notifyListeners();
  }

  void setShowFriends(bool v) {
    me?.showFriends = v;
    notifyListeners();
  }

  void setAllowComments(bool v) {
    me?.allowComments = v;
    notifyListeners();
  }

  void setNotifications(bool v) {
    me?.notifications = v;
    notifyListeners();
  }

  bool canSeePost(Post p) {
    final viewer = me;
    if (viewer == null) return false;
    if (p.authorId == viewer.id) return true;
    switch (p.audience) {
      case Audience.everyone:
        return true;
      case Audience.friends:
        final author = _byId[p.authorId];
        return author != null && author.friends.contains(viewer.id);
      case Audience.onlyMe:
        return false;
    }
  }

  List<Post> visiblePosts() => posts.where(canSeePost).toList();

  List<Post> postsOf(Account a) =>
      posts.where((p) => p.authorId == a.id && canSeePost(p)).toList();

  List<Story> visibleStories() {
    final viewer = me;
    if (viewer == null) return <Story>[];
    final limit = DateTime.now().subtract(const Duration(hours: 24));
    return stories.where((s) {
      if (s.created.isBefore(limit)) return false;
      if (s.authorId == viewer.id) return true;
      final author = _byId[s.authorId];
      return author != null && author.friends.contains(viewer.id);
    }).toList();
  }

  // ───── المنشورات
  void addPost(String text, Audience audience) {
    final a = me;
    if (a == null || text.trim().isEmpty) return;
    _seq++;
    posts.insert(
      0,
      Post(
        id: 'p$_seq',
        authorId: a.id,
        created: DateTime.now(),
        text: text.trim(),
        audience: audience,
      ),
    );
    notifyListeners();
  }

  void deletePost(Post p) {
    if (me?.id != p.authorId) return;
    posts.remove(p);
    notifyListeners();
  }

  void react(Post p, Reaction r) {
    final a = me;
    if (a == null) return;
    if (p.reactions[a.id] == r) {
      p.reactions.remove(a.id);
    } else {
      p.reactions[a.id] = r;
    }
    notifyListeners();
  }

  void addComment(Post p, String text) {
    final a = me;
    if (a == null || text.trim().isEmpty) return;
    p.comments.add(Comment(a.id, text.trim()));
    notifyListeners();
  }

  void share(Post p) {
    p.shares += 1;
    notifyListeners();
  }

  void addStory(String text, int gradient) {
    final a = me;
    if (a == null || text.trim().isEmpty) return;
    _seq++;
    stories.insert(
      0,
      Story(
        id: 's$_seq',
        authorId: a.id,
        text: text.trim(),
        gradient: gradient,
        created: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // ───── الأصدقاء
  List<Account> people() {
    final a = me;
    if (a == null) return <Account>[];
    return _byId.values
        .where((o) => o.id != a.id && o.onboarded && !a.friends.contains(o.id))
        .toList();
  }

  FriendState stateWith(Account other) {
    final a = me;
    if (a == null) return FriendState.none;
    if (a.friends.contains(other.id)) return FriendState.friends;
    if (a.incoming.contains(other.id)) return FriendState.incoming;
    if (a.outgoing.contains(other.id)) return FriendState.outgoing;
    return FriendState.none;
  }

  void sendRequest(Account other) {
    final a = me;
    if (a == null || !other.allowRequests) return;
    if (a.incoming.contains(other.id)) {
      accept(other);
      return;
    }
    a.outgoing.add(other.id);
    other.incoming.add(a.id);
    notifyListeners();
  }

  void cancelRequest(Account other) {
    final a = me;
    if (a == null) return;
    a.outgoing.remove(other.id);
    other.incoming.remove(a.id);
    notifyListeners();
  }

  void accept(Account other) {
    final a = me;
    if (a == null) return;
    a.incoming.remove(other.id);
    other.outgoing.remove(a.id);
    a.friends.add(other.id);
    other.friends.add(a.id);
    notifyListeners();
  }

  void decline(Account other) {
    final a = me;
    if (a == null) return;
    a.incoming.remove(other.id);
    other.outgoing.remove(a.id);
    notifyListeners();
  }

  void unfriend(Account other) {
    final a = me;
    if (a == null) return;
    a.friends.remove(other.id);
    other.friends.remove(a.id);
    notifyListeners();
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
    final initial =
        trimmed.isEmpty ? '؟' : String.fromCharCode(trimmed.runes.first);
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

Widget avatarOf(Account a, double size) => AvatarView(
      name: a.name,
      gradient: a.gradient,
      emoji: a.emoji,
      size: size,
    );

/// منتقي الصورة الشخصية (تدرّج لوني + رمز تعبيري أو الحرف الأول)
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
                      color: i == gradient ? Colors.white : Colors.transparent,
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

/// زر الصداقة المتغيّر حسب الحالة
class FriendActionButton extends StatelessWidget {
  final AppStore store;
  final Account other;
  const FriendActionButton({super.key, required this.store, required this.other});

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
            store.accept(other);
            showMsg(context, 'أصبحت الآن صديقاً لـ ${other.name} 🤝');
          },
          child: const Text('قبول الطلب'),
        );
      case FriendState.outgoing:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 36),
            side: BorderSide(color: alpha(Colors.white, 0.2)),
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
            store.sendRequest(other);
            showMsg(context, 'تم إرسال طلب صداقة إلى ${other.name}');
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
  final AppStore _store = AppStore();

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'فلاتر سوشيال',
      theme: buildTheme(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
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
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final err = _isLogin
        ? widget.store.logIn(_emailCtrl.text, _passCtrl.text)
        : widget.store.signUp(_emailCtrl.text, _passCtrl.text);
    if (err != null && mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  Future<void> _google() async {
    if (_loading || _googleLoading) return;
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    widget.store.googleDemo();
  }

  @override
  Widget build(BuildContext context) {
    final strength = _strength;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1A), Color(0xFF0D2238), Color(0xFF0A0F1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                        border: Border.all(color: alpha(Colors.white, 0.07)),
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
                                  final ok =
                                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                          .hasMatch(t);
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
                color: ok ? Colors.white : AppColors.textDim,
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
        Expanded(child: Divider(color: alpha(Colors.white, 0.1))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('أو', style: TextStyle(color: AppColors.textDim)),
        ),
        Expanded(child: Divider(color: alpha(Colors.white, 0.1))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.white,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1A), Color(0xFF0D2238), Color(0xFF0A0F1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
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
                        border: Border.all(color: alpha(Colors.white, 0.07)),
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

class HomeShell extends StatefulWidget {
  final AppStore store;
  const HomeShell({super.key, required this.store});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final me = store.me;
    if (me == null) return const SizedBox.shrink();

    final tabs = <Widget>[
      HomeTab(store: store),
      FriendsTab(store: store),
      ProfileTab(store: store),
    ];
    final requests = me.incoming.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brand,
              ),
              child: const Icon(Icons.hub_rounded, size: 19, color: Colors.white),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (r) => AppColors.brand.createShader(r),
              child: const Text(
                'SocialVerse',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'الإشعارات',
            icon: Badge(
              isLabelVisible: requests > 0 && me.notifications,
              label: Text('$requests'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
            onPressed: () {
              if (requests > 0) {
                setState(() => _index = 1);
              } else {
                showMsg(context, 'لا توجد إشعارات جديدة');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: IndexedStack(index: _index, children: tabs),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: alpha(Colors.white, 0.06))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.cyan,
          unselectedItemColor: AppColors.textDim,
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
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'الملف الشخصي',
            ),
          ],
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
                          widget.store.addStory(_ctrl.text, _gradient);
                          Navigator.of(context).pop();
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
  const CreatePostBox({super.key, required this.store});

  @override
  State<CreatePostBox> createState() => _CreatePostBoxState();
}

class _CreatePostBoxState extends State<CreatePostBox> {
  final _ctrl = TextEditingController();
  Audience? _audience;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _insertEmoji(String e) {
    _ctrl.text = '${_ctrl.text}$e';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  void _publish(Audience audience) {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    widget.store.addPost(t, audience);
    _ctrl.clear();
    FocusScope.of(context).unfocus();
    showMsg(context, 'تم نشر منشورك 🎉');
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.store.me;
    if (me == null) return const SizedBox.shrink();
    final audience = _audience ?? me.defaultAudience;
    final firstName = me.name.trim().split(' ').first;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatarOf(me, 42),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'بماذا تفكر يا $firstName؟',
                    hintStyle: const TextStyle(color: AppColors.textDim),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surface2,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final e in const ['😊', '❤️', '🔥'])
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _insertEmoji(e),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(e, style: const TextStyle(fontSize: 21)),
                  ),
                ),
              const SizedBox(width: 4),
              PopupMenuButton<Audience>(
                tooltip: 'من يرى المنشور؟',
                color: AppColors.surface2,
                onSelected: (a) => setState(() => _audience = a),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(audience.icon, size: 15, color: AppColors.cyan),
                      const SizedBox(width: 4),
                      Text(audience.label, style: const TextStyle(fontSize: 12.5)),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _ctrl,
                builder: (context, value, _) {
                  final has = value.text.trim().isNotEmpty;
                  return SizedBox(
                    width: 104,
                    child: GradientButton(
                      label: 'نشر',
                      icon: Icons.send_rounded,
                      onPressed: has ? () => _publish(audience) : null,
                    ),
                  );
                },
              ),
            ],
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
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              post.text,
              style: const TextStyle(fontSize: 15.5, height: 1.55),
            ),
          ),
          _summary(),
          Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: alpha(Colors.white, 0.07),
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

  Widget _likeLabel() {
    final m = _mine;
    if (m == null) {
      return const Row(
        key: ValueKey<String>('none'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thumb_up_alt_outlined, size: 20, color: AppColors.textDim),
          SizedBox(width: 6),
          Text('أعجبني', style: TextStyle(color: AppColors.textDim, fontSize: 14)),
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
                child: Text(list[i].emoji, style: const TextStyle(fontSize: 11)),
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
          border: Border.all(color: alpha(Colors.white, 0.08)),
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
    widget.store.addComment(widget.post, t);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final comments = widget.post.comments;
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: alpha(Colors.white, 0.2),
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
                            hintStyle:
                                const TextStyle(color: AppColors.textDim),
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
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
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
          GestureDetector(
            onTap: () => _openProfile(a),
            child: avatarOf(a, 46),
          ),
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

    final requests = me.incoming
        .map(store.byId)
        .whereType<Account>()
        .toList();
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
                                store.accept(a);
                                showMsg(
                                  context,
                                  'أصبحت الآن صديقاً لـ ${a.name} 🤝',
                                );
                              },
                              child: const Text('تأكيد'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 38),
                                side: BorderSide(
                                  color: alpha(Colors.white, 0.18),
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
        const SectionTitle('أشخاص على التطبيق'),
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
          _personRow(a, trailing: FriendActionButton(store: store, other: a)),
        SectionTitle('أصدقائي', badge: friends.isEmpty ? null : '${friends.length}'),
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
                  store.unfriend(a);
                  showMsg(context, 'تم إلغاء الصداقة مع ${a.name}');
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
                      color: alpha(Colors.white, 0.14),
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: alpha(Colors.white, 0.2)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              Container(width: 1, height: 30, color: alpha(Colors.white, 0.1)),
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
//  نافذة تعديل الملف الشخصي (الاسم + النبذة + الصورة)
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
    widget.store.updateProfile(_name.text, _bio.text, _gradient, _emoji);
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
                  decoration: inputDeco('النبذة التعريفية', Icons.notes_rounded),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: alpha(Colors.white, 0.18)),
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
//  شاشة إعدادات الخصوصية (تُطبَّق فوراً)
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
                      style: TextStyle(color: AppColors.textDim, fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<Audience>(
                      showSelectedIcon: false,
                      segments: [
                        for (final a in Audience.values)
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
//  ملف شخص آخر (يحترم إعدادات الخصوصية)
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
        final posts = store.postsOf(a);
        final friendsText = (a.showFriends || a.id == me.id)
            ? '${a.friends.length}'
            : 'مخفي';

        return Scaffold(
          appBar: AppBar(title: Text(a.name)),
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
                    PostCard(key: ValueKey('pp-${p.id}'), store: store, post: p),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
