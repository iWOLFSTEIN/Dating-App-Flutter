import 'package:firebase_admob/firebase_admob.dart';

var AdmobAppId = 'ca-app-pub-5913555696266241~8018099393';

var AdmobBannerAdsId = 'ca-app-pub-5913555696266241/8423641112';

var AdmobInterstitialAdsId = 'ca-app-pub-5913555696266241/4917293330';

var AdmobRewardedAdsId = 'ca-app-pub-5913555696266241/9545151099';

MobileAdTargetingInfo TargetingInfo = MobileAdTargetingInfo(
  keywords: <String>['flutterio', 'beautiful apps'],
  contentUrl: 'https://flutter.io',
  childDirected: false,
  testDevices: <String>[],
);

// BannerAd myBanner = BannerAd(
//   adUnitId: BannerAd.testAdUnitId,
//   size: AdSize.smartBanner,
//   targetingInfo: TargetingInfo,
//   listener: (MobileAdEvent event) {
//     print("BannerAd event is $event");
//   },
// );

// showBanner() {
//   myBanner
//     ..load()
//     ..show(
//       anchorOffset: 60.0,
//       horizontalCenterOffset: 10.0,
//       anchorType: AnchorType.bottom,
//     );
// }
