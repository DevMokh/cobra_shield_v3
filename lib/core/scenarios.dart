import 'package:flutter/material.dart';

// سيناريوهات التدريب. كل الدومينات والأرقام والأسماء وهمية لغرض التعليم.

enum Channel { sms, whatsapp, email, link }

extension ChannelX on Channel {
  String get label {
    switch (this) {
      case Channel.sms:
        return 'رسالة SMS';
      case Channel.whatsapp:
        return 'واتساب';
      case Channel.email:
        return 'إيميل';
      case Channel.link:
        return 'رابط';
    }
  }

  IconData get icon {
    switch (this) {
      case Channel.sms:
        return Icons.sms_rounded;
      case Channel.whatsapp:
        return Icons.chat_rounded;
      case Channel.email:
        return Icons.email_rounded;
      case Channel.link:
        return Icons.link_rounded;
    }
  }
}

class Scenario {
  const Scenario({
    required this.channel,
    required this.sender,
    required this.text,
    required this.isScam,
    required this.explanation,
    this.clues = const <String>[],
  });

  final Channel channel;
  final String sender;
  final String text;
  final bool isScam;
  final String explanation;
  final List<String> clues;
}

class TrainLevel {
  const TrainLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.scenarios,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Scenario> scenarios;
}

/// أقل عدد إجابات صحيحة لفتح المرحلة التالية
const int kPassMark = 4;

int starsFor(int correct, int total) {
  if (correct >= total) return 3;
  if (correct >= total - 1) return 2;
  if (correct >= kPassMark) return 1;
  return 0;
}

const List<TrainLevel> kLevels = <TrainLevel>[
  // -------------------------------------------------------------------
  TrainLevel(
    id: 'l1',
    title: 'المرحلة 1: العين المبتدئة',
    subtitle: 'علامات واضحة تكشف الاحتيال',
    icon: Icons.visibility_rounded,
    scenarios: <Scenario>[
      Scenario(
        channel: Channel.sms,
        sender: 'رقم غير معروف',
        text:
            'مبروك! ربحت 100,000 جنيه في سحب الموبايلات. اضغط للاستلام الآن: http://win-prize-now.top/claim',
        isScam: true,
        explanation:
            'جائزة في سحب لم تشترك فيه، وضغط للاستلام "الآن"، ورابط HTTP بامتداد .top غير معروف.',
        clues: <String>['جائزة غير متوقعة', 'استعجال', 'دومين غريب'],
      ),
      Scenario(
        channel: Channel.sms,
        sender: 'Vodafone',
        text:
            'تنبيه: سيتم إيقاف خطك خلال ساعتين! حدّث بياناتك فورًا: http://vodafone-egypt.update-line.xyz',
        isScam: true,
        explanation:
            'الدومين الحقيقي هنا هو update-line.xyz، واسم الشركة مجرد جزء فرعي. والتهديد بإيقاف الخط أسلوب شائع.',
        clues: <String>['تهديد بالإيقاف', 'دومين فرعي مضلّل', 'استعجال'],
      ),
      Scenario(
        channel: Channel.sms,
        sender: 'البنك',
        text:
            'كود التحقق لعملية الدفع الإلكتروني 539218. لا تشاركه مع أي شخص. إذا لم تقم بالعملية تجاهل الرسالة واتصل بالبنك.',
        isScam: false,
        explanation:
            'رسالة كود رسمية: بدون رابط، وتحذّرك من المشاركة. لكن لو لم تطلب أي عملية فلا تعطِ الكود لأحد وتواصل مع البنك من الرقم الرسمي.',
        clues: <String>['بدون رابط', 'تحذير من مشاركة الكود'],
      ),
      Scenario(
        channel: Channel.whatsapp,
        sender: 'رقم جديد',
        text:
            'أنا ابن عمك، رقمي اتغير. محتاج تحويل 3000 جنيه ضروري دلوقتي وماتقولش لحد.',
        isScam: true,
        explanation:
            'انتحال هوية قريب + طلب فلوس + استعجال + طلب سرية. اتصل بقريبك على رقمه القديم قبل أي تحويل.',
        clues: <String>['انتحال هوية', 'طلب مال', 'سرية'],
      ),
      Scenario(
        channel: Channel.email,
        sender: 'delivery-notice@parcel-fee-check.click',
        text:
            'Your package could not be delivered. Pay a 15 EGP fee to reschedule: http://parcel-fee-check.click/pay',
        isScam: true,
        explanation:
            'رسوم صغيرة لتعذر التسليم وبدون ذكر الشركة، ودومين .click. الهدف سرقة بيانات بطاقتك.',
        clues: <String>['رسوم توصيل', 'دومين .click', 'لا اسم شركة'],
      ),
      Scenario(
        channel: Channel.link,
        sender: 'رابط من صديق',
        text: 'https://ar.wikipedia.org/wiki/مصر',
        isScam: false,
        explanation:
            'دومين معروف (wikipedia.org) وHTTPS ولا يطلب أي بيانات. لا علامات خطر.',
        clues: <String>['دومين معروف', 'لا يطلب بيانات'],
      ),
    ],
  ),
  // -------------------------------------------------------------------
  TrainLevel(
    id: 'l2',
    title: 'المرحلة 2: القناص',
    subtitle: 'احتيال متنكر بشكل رسمي',
    icon: Icons.gps_fixed_rounded,
    scenarios: <Scenario>[
      Scenario(
        channel: Channel.link,
        sender: 'رابط وصلك برسالة',
        text: 'https://paypal.com.account-verify.xyz/login',
        isScam: true,
        explanation:
            'اقرأ الدومين من اليمين: الدومين الحقيقي هو account-verify.xyz. وكلمة paypal.com مجرد جزء فرعي لخداعك.',
        clues: <String>['الدومين الحقيقي مختلف', 'صفحة login'],
      ),
      Scenario(
        channel: Channel.link,
        sender: 'رابط وصلك برسالة',
        text: 'https://paypa1.com/signin',
        isScam: true,
        explanation:
            'الرقم 1 بدل الحرف l. تغيير حرف واحد كفيل بنقلك لموقع مزيف.',
        clues: <String>['حرف مستبدل', 'تقليد اسم معروف'],
      ),
      Scenario(
        channel: Channel.sms,
        sender: 'البنك',
        text:
            'تم خصم 450 جنيه من حسابك. إذا لم تقم بالعملية اتصل بالبنك على الرقم المطبوع خلف بطاقتك.',
        isScam: false,
        explanation:
            'لا رابط، ولا يطلب بيانات، ويوجّهك للرقم المطبوع على بطاقتك (وليس رقمًا جديدًا في الرسالة). نمط رسمي.',
        clues: <String>['بدون رابط', 'رقم البطاقة الرسمي'],
      ),
      Scenario(
        channel: Channel.sms,
        sender: 'إدارة المرور',
        text:
            'مخالفة مرورية بقيمة 300 جنيه. ادفع خلال 24 ساعة لتجنب الغرامة المضاعفة: https://traffic-pay.top/fine',
        isScam: true,
        explanation:
            'الجهات الحكومية لا ترسل روابط دفع بهذا الشكل، والدومين .top غير حكومي، وهناك استعجال وتهديد بغرامة.',
        clues: <String>['غرامة مضاعفة', 'دومين غير رسمي', 'استعجال'],
      ),
      Scenario(
        channel: Channel.link,
        sender: 'رابط بحث',
        text: 'https://secure-amazon.eg.login-check.com/ap/signin',
        isScam: true,
        explanation:
            'الدومين الحقيقي هو login-check.com. كلمات amazon.eg في المنتصف مجرد تمويه.',
        clues: <String>['مستويات فرعية كثيرة', 'شرطات وكلمات حساسة'],
      ),
      Scenario(
        channel: Channel.link,
        sender: 'رابط بحث',
        text: 'https://www.amazon.eg/gp/help/customer/display.html',
        isScam: false,
        explanation:
            'دومين amazon.eg الرسمي بعد www مباشرة، وصفحة مساعدة عادية بدون طلب بيانات.',
        clues: <String>['دومين رسمي', 'صفحة مساعدة'],
      ),
    ],
  ),
  // -------------------------------------------------------------------
  TrainLevel(
    id: 'l3',
    title: 'المرحلة 3: كوبرا',
    subtitle: 'تفاصيل دقيقة يفوّتها معظم الناس',
    icon: Icons.workspace_premium_rounded,
    scenarios: <Scenario>[
      Scenario(
        channel: Channel.link,
        sender: 'رابط متجر',
        text: 'https://www.arnazon.com/orders',
        isScam: true,
        explanation:
            'اقرأها حرفًا حرفًا: arnazon وليس amazon. الحرفان rn يشبهان m عند القراءة السريعة.',
        clues: <String>['rn بدل m'],
      ),
      Scenario(
        channel: Channel.link,
        sender: 'رابط دعم',
        text: 'https://support.apple.com/ar-eg',
        isScam: false,
        explanation:
            'دومين apple.com الرسمي (support مجرد قسم فرعي) وبدون علامات تمويه.',
        clues: <String>['دومين رسمي'],
      ),
      Scenario(
        channel: Channel.email,
        sender: 'billing@your-company.example',
        text:
            'فاتورتك لهذا الشهر جاهزة. لمراجعتها افتح تطبيق الشركة بنفسك من حسابك (نحن لا نرسل روابط دفع بالرسائل).',
        isScam: false,
        explanation:
            'لا رابط ولا طلب بيانات، وتطلب منك فتح التطبيق الرسمي بنفسك. هذا هو السلوك الآمن.',
        clues: <String>['لا رابط', 'توجيه للتطبيق الرسمي'],
      ),
      Scenario(
        channel: Channel.sms,
        sender: 'خدمة العملاء',
        text:
            'لتحديث بيانات حسابك اتصل بنا الآن على 01012345678 وأخبر الموظف برقمك القومي وكود التحقق الذي سيصلك.',
        isScam: true,
        explanation:
            'لا رابط هنا، لكنه احتيال هاتفي: رقم جديد غير رسمي، وطلب رقم قومي وكود التحقق. الأكواد لا تُعطى لأحد.',
        clues: <String>['طلب كود التحقق', 'رقم جديد غير رسمي', 'طلب الرقم القومي'],
      ),
      Scenario(
        channel: Channel.link,
        sender: 'رابط نموذج',
        text: 'https://sites.google.com/view/bank-login-update',
        isScam: true,
        explanation:
            'الدومين google.com حقيقي لكن sites.google.com يتيح لأي شخص إنشاء صفحة. صفحة "bank login" هناك فخ شائع.',
        clues: <String>['استضافة مجانية', 'كلمات bank login'],
      ),
      Scenario(
        channel: Channel.link,
        sender: 'رابط وصلك برسالة',
        text: 'https://mail.google.com@evil-login.com/inbox',
        isScam: true,
        explanation:
            'كل ما قبل علامة @ يتجاهله المتصفح. الموقع الفعلي هو evil-login.com وليس Google.',
        clues: <String>['علامة @', 'الدومين الحقيقي بعدها'],
      ),
    ],
  ),
];

int get kTotalQuestions =>
    kLevels.fold<int>(0, (a, l) => a + l.scenarios.length);
