class TutorialStep {
  final String title;
  final String description;
  final String? imagePath;
  final TutorialHighlight? highlight;

  const TutorialStep({
    required this.title,
    required this.description,
    this.imagePath,
    this.highlight,
  });
}

enum TutorialHighlight { board, dice, bar, bearOff, timer, actions }

const tutorialSteps = [
  TutorialStep(
    title: 'Tavla\'ya Hoş Geldin!',
    description:
        'Tavla, iki kişiyle oynanan stratejik bir zar oyunudur. '
        'Her oyuncunun 15 pulu vardır ve amaç tüm pullarını tahtadan çıkarmaktır.',
  ),
  TutorialStep(
    title: 'Tahta Düzeni',
    description:
        'Tahta 24 üçgen (point) içerir ve 4 bölgeye ayrılır: '
        'her oyuncunun iç ve dış sahası. Pullarını iç sahana getirmen gerekir.',
    highlight: TutorialHighlight.board,
  ),
  TutorialStep(
    title: 'Zar Atma',
    description:
        'Her turda iki zar atarsın. Zarların gösterdiği sayılar kadar '
        'pullarını hareket ettirirsin. Çift atarsan 4 hamle yaparsın!',
    highlight: TutorialHighlight.dice,
  ),
  TutorialStep(
    title: 'Pul Hareketi',
    description:
        'Beyaz pullar yüksek numaradan düşük numaraya, '
        'siyah pullar düşükten yükseğe hareket eder. '
        'Önce pula dokun, sonra hedef noktaya dokun.',
    highlight: TutorialHighlight.board,
  ),
  TutorialStep(
    title: 'Geçerli Hamleler',
    description:
        'Bir pul seçtiğinde geçerli hedefler yeşil ile gösterilir. '
        'Rakip tek pul olan noktalar kırmızı ile gösterilir (kırma).',
  ),
  TutorialStep(
    title: 'Kırma (Hit)',
    description:
        'Eğer rakibin 1 pulunun olduğu noktaya gelirsen, '
        'o pul "bar"a gider. Rakip sırasında tekrar tahtaya girmelidir.',
    highlight: TutorialHighlight.bar,
  ),
  TutorialStep(
    title: 'Bardan Giriş',
    description:
        'Bar\'da pulun varsa, önce onu rakibin iç sahasına sokmalısın. '
        'Zar ile uygun boş nokta bulana kadar başka hamle yapamazsın.',
    highlight: TutorialHighlight.bar,
  ),
  TutorialStep(
    title: 'Taşları Kırma (Bear Off)',
    description:
        'Tüm 15 pulun iç sahana gelince "kırma" aşamasına geçersin. '
        'Zarları kullanarak pullarını tahtadan çıkarırsın.',
    highlight: TutorialHighlight.bearOff,
  ),
  TutorialStep(
    title: 'Süre Limiti',
    description:
        'Her hamle için 60 saniye süren var. '
        'Süre dolunca sıra otomatik olarak rakibe geçer. '
        'Son 10 saniyede uyarı alırsın!',
    highlight: TutorialHighlight.timer,
  ),
  TutorialStep(
    title: 'Hazırsın!',
    description:
        'Artık tavla oynamaya hazırsın! İlk başta bot ile '
        'pratik yapabilir, sonra gerçek oyunculara karşı oynayabilirsin. '
        'İyi şanslar! 🎲',
    highlight: TutorialHighlight.actions,
  ),
];
