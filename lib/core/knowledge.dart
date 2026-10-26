export 'brands.dart';

// قواعد المعرفة: قوائم الدومينات والكلمات المستخدمة في التحليل.
// تقدر تعدّل أي قائمة هنا وتضيف عليها بدون لمس باقي الكود.

const Set<String> kShorteners = <String>{
  'bit.ly', 'tinyurl.com', 't.co', 'goo.gl', 'ow.ly', 'is.gd', 'buff.ly',
  'rebrand.ly', 'cutt.ly', 'shorturl.at', 't.ly', 'rb.gy', 'tiny.cc',
  'bl.ink', 'lnkd.in', 's.id', 'v.gd', 'soo.gd', 'clck.ru', 'adf.ly',
  'bit.do', 'shorte.st', 'qrco.de', 'urlz.fr', 'x.co',
};

const Set<String> kRiskyTlds = <String>{
  'zip', 'mov', 'xyz', 'top', 'click', 'country', 'gq', 'tk', 'ml', 'cf',
  'ga', 'work', 'support', 'rest', 'loan', 'icu', 'cyou', 'buzz', 'monster',
  'sbs', 'cfd', 'vip', 'men', 'win', 'bid', 'stream', 'download', 'racing',
  'review', 'date', 'party', 'trade', 'webcam', 'science', 'accountant',
};

// امتدادات الدومين المركّب (co.uk / com.eg ...)
const Set<String> kSecondLevel = <String>{
  'co', 'com', 'org', 'net', 'gov', 'edu', 'ac',
};

// استضافات مجانية/منصات محتوى يستغلها المحتالون كثيرًا
const List<String> kFreeHosts = <String>[
  'sites.google.com', 'docs.google.com', 'forms.gle', 'drive.google.com',
  'storage.googleapis.com', 'firebaseapp.com', 'web.app', 'github.io',
  'netlify.app', 'vercel.app', 'pages.dev', 'workers.dev', 'blogspot.com',
  'weebly.com', 'wixsite.com', 'herokuapp.com', 'glitch.me',
  '000webhostapp.com', 'trycloudflare.com', 'ngrok.io', 'ngrok-free.app',
  'onrender.com', 'repl.co', 'wordpress.com',
];

const List<String> kUrlWords = <String>[
  'login', 'log-in', 'signin', 'sign-in', 'verify', 'verification', 'secure',
  'account', 'update', 'confirm', 'wallet', 'password', 'passwd', 'bank',
  'billing', 'suspend', 'unlock', 'recover', 'restore', 'validate',
  'authenticate', 'otp', 'payment', 'invoice', 'refund', 'gift', 'claim',
  'reward', 'prize', 'pay',
];

const Set<String> kRedirectParams = <String>{
  'url', 'u', 'redirect', 'redirect_uri', 'redirecturl', 'next', 'continue',
  'return', 'returnurl', 'dest', 'destination', 'goto', 'link', 'target', 'r',
};

const List<String> kDangerExt = <String>[
  '.apk', '.exe', '.scr', '.bat', '.cmd', '.msi', '.jar', '.vbs', '.js',
  '.ps1', '.lnk', '.iso', '.dmg',
];

const List<String> kArchiveExt = <String>['.zip', '.rar', '.7z'];

// ---------------------------------------------------------------------------
// إشارات الرسائل
// ---------------------------------------------------------------------------

class SignalDef {
  const SignalDef({
    required this.id,
    required this.title,
    required this.detail,
    required this.weight,
    required this.words,
  });

  final String id;
  final String title;
  final String detail;
  final int weight;
  final List<String> words;
}

const List<SignalDef> kSignals = <SignalDef>[
  SignalDef(
    id: 'secret',
    title: 'يطلب كودًا أو بيانات سرية',
    detail:
        'الجهات الحقيقية (البنوك والمحافظ والشركات) لا تطلب منك كود التحقق أو الرقم السري أو بيانات البطاقة عبر رسالة.',
    weight: 28,
    words: <String>[
      'كود التحقق', 'رمز التحقق', 'كود التفعيل', 'الرقم السري', 'الرمز السري',
      'كلمة المرور', 'كلمه المرور', 'باسورد', 'الرقم القومي', 'رقم البطاقة',
      'بيانات البطاقة', 'بيانات حسابك', 'otp', 'cvv', 'pin', 'password',
      'verification code', 'security code', 'one-time code',
    ],
  ),
  SignalDef(
    id: 'urgency',
    title: 'استعجال وضغط نفسي',
    detail: 'المحتال يحاول يخليك تتصرف بسرعة قبل ما تفكّر أو تتأكد.',
    weight: 12,
    words: <String>[
      'فورا', 'عاجل', 'عاجلا', 'الان', 'خلال 24 ساعة', 'خلال 48 ساعة',
      'اخر فرصة', 'اخر تحذير', 'قبل فوات', 'ينتهي اليوم', 'قبل انتهاء',
      'urgent', 'immediately', 'right now', 'asap', 'within 24 hours',
      'within 48 hours', 'last chance', 'final notice', 'act now',
      'expires today',
    ],
  ),
  SignalDef(
    id: 'threat',
    title: 'تهديد بإيقاف أو حظر',
    detail: 'التهديد بإغلاق الحساب أو الغرامة أسلوب شائع لدفعك للضغط على الرابط.',
    weight: 16,
    words: <String>[
      'تم ايقاف', 'سيتم ايقاف', 'ايقاف حسابك', 'تعليق حسابك', 'تم تعليق',
      'سيتم تعليق', 'تم حظر', 'سيتم حظر', 'حظر حسابك', 'اغلاق حسابك',
      'سيتم اغلاق', 'تم تجميد', 'تجميد حسابك', 'نشاط مشبوه', 'محاولة دخول',
      'تم اختراق', 'اجراء قانوني', 'بلاغ ضدك', 'suspended', 'locked',
      'blocked', 'terminated', 'unauthorized', 'suspicious activity',
      'unusual activity', 'account will be closed', 'security alert',
      'legal action',
    ],
  ),
  SignalDef(
    id: 'prize',
    title: 'جائزة أو مبلغ مستحق غير متوقع',
    detail: 'لو ما اشتركتش في سحب أو ما كنتش منتظر استرداد، فالأغلب إنها خدعة.',
    weight: 18,
    words: <String>[
      'مبروك', 'ربحت', 'فزت', 'جائزة', 'هدية مجانية', 'تم اختيارك',
      'مبلغ مستحق', 'استرداد', 'كاش باك', 'congratulations', 'you won',
      'you have won', 'winner', 'prize', 'lottery', 'free gift',
      'claim your', 'refund', 'cashback',
    ],
  ),
  SignalDef(
    id: 'payment',
    title: 'طلب دفع أو تحويل أموال',
    detail: 'احذر من أي رسوم أو تحويل يُطلب عبر رابط أو بطاقة هدايا أو محفظة.',
    weight: 10,
    words: <String>[
      'حول مبلغ', 'تحويل مبلغ', 'ادفع', 'دفع رسوم', 'رسوم الشحن',
      'رسوم التوصيل', 'رسوم', 'بطاقة هدايا', 'فودافون كاش', 'انستاباي',
      'فاتورة', 'gift card', 'bitcoin', 'crypto', 'usdt', 'western union',
      'invoice', 'pay now', 'wire transfer',
    ],
  ),
  SignalDef(
    id: 'delivery',
    title: 'رسالة طرد أو شحنة',
    detail: 'رسائل "تعذر التسليم" و"رسوم شحن" من أكثر أساليب التصيّد انتشارًا.',
    weight: 10,
    words: <String>[
      'طردك', 'شحنتك', 'تعذر التسليم', 'فشل التوصيل', 'عنوانك غير مكتمل',
      'لم نتمكن من توصيل', 'البريد المصري', 'ارامكس', 'package', 'parcel',
      'delivery failed', 'tracking number', 'shipment', 'dhl', 'aramex',
      'fedex',
    ],
  ),
  SignalDef(
    id: 'scheme',
    title: 'عرض ربح أو استثمار مضمون',
    detail: 'لا يوجد ربح مضمون. العروض السريعة المبالغ فيها غالبًا نصب.',
    weight: 14,
    words: <String>[
      'ربح مضمون', 'ارباح مضمونة', 'دخل يومي', 'استثمر', 'استثمار مضمون',
      'عمل من المنزل', 'وظيفة من المنزل', 'مضاعفة اموالك', 'توصيات',
      'guaranteed profit', 'double your', 'work from home',
      'investment opportunity', 'daily income', 'passive income', 'forex',
      'binary options',
    ],
  ),
  SignalDef(
    id: 'secrecy',
    title: 'يطلب السرية',
    detail: 'المحتال يطلب منك ألا تخبر أحدًا حتى لا يتدخل أحد وينبّهك.',
    weight: 12,
    words: <String>[
      'لا تخبر', 'بسرية تامة', 'الامر سري', 'لا تتحدث مع احد',
      'keep this secret', 'do not tell', 'confidential',
    ],
  ),
  SignalDef(
    id: 'cta',
    title: 'يطلب الضغط على رابط أو تسجيل الدخول',
    detail: 'صيغة "اضغط هنا" و"سجّل الدخول" شائعة في رسائل التصيّد.',
    weight: 6,
    words: <String>[
      'اضغط', 'انقر', 'افتح الرابط', 'عبر الرابط', 'من خلال الرابط',
      'سجل الدخول', 'تسجيل الدخول', 'click here', 'tap here', 'click the link',
      'log in', 'login', 'sign in', 'follow the link',
    ],
  ),
  SignalDef(
    id: 'authority',
    title: 'ينتحل صفة جهة رسمية',
    detail: 'ذكر البنك أو الأمن أو الدعم الفني لا يعني أن المرسل منهم فعلًا.',
    weight: 5,
    words: <String>[
      'البنك', 'الشرطة', 'النيابة', 'مصلحة الضرائب', 'شركة الكهرباء',
      'الدعم الفني', 'فريق الدعم', 'خدمة العملاء', 'security team',
      'support team', 'customer service', 'bank',
    ],
  ),
];

// عبارات تحذير شائعة في الرسائل الرسمية الحقيقية (تخفّف درجة طلب الكود)
const List<String> kSafeHints = <String>[
  'لا تشارك', 'لا تعطي', "do not share", "don't share", 'never share',
];
