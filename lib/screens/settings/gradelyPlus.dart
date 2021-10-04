import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:gradely2/main.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:gradely2/shared/FUNCTIONS.dart';
import 'package:gradely2/shared/VARIABLES.dart';
import 'package:gradely2/shared/WIDGETS.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:gradely2/shared/loading.dart';

class GradelyPlus extends StatefulWidget {
  @override
  _GradelyPlusState createState() => _GradelyPlusState();
}

class _GradelyPlusState extends State<GradelyPlus> {
  StreamSubscription purchaseUpdatedSubscription;
  StreamSubscription purchaseErrorSubscription;
  StreamSubscription _conectionSubscription;
  List iapList = [];

  buyProduct(String id) async {
    isLoadingController.add(true);
    initPlatformState();
    await FlutterInappPurchase.instance.clearTransactionIOS();

    await getProducts();
    await FlutterInappPurchase.instance.requestPurchase(id);
  }

  getProducts() async {
    if (Platform.isIOS || Platform.isAndroid) {
      var result = await FlutterInappPurchase.instance.initConnection;
      print('result: $result');
      await FlutterInappPurchase.instance.clearTransactionIOS();
      iapList = (await FlutterInappPurchase.instance.getProducts([
        "com.eliasschneider.gradely2.iap.gradelyplus",
        "com.eliasschneider.gradely2.iap.gradelyplus2",
        "com.eliasschneider.gradely2.iap.gradelyplus5"
      ]));
      setState(() {
        iapList = iapList;
      });
      print(iapList);
    }
  }

  finishPurchase() async {
    isLoadingController.add(false);

    database.updateDocument(
        collectionId: collectionUser,
        documentId: user.dbID,
        data: {'gradelyPlus': true});

    Navigator.push(
      context,
      GradelyPageRoute(builder: (context) => HomeWrapper()),
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
            title: Text("🎉 Wohooo"),
            content: Text("gradely_pluss_success_text".tr()),
            actions: <Widget>[
              gradelyButton(
                text: "ok",
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    getProducts();
  }

  @override
  void dispose() {
    super.dispose();
    if (_conectionSubscription != null) {
      _conectionSubscription.cancel();
      _conectionSubscription = null;
    }
    if (purchaseErrorSubscription != null) {
      purchaseErrorSubscription.cancel();
      purchaseErrorSubscription = null;
    }
    if (purchaseUpdatedSubscription != null) {
      purchaseUpdatedSubscription.cancel();
      purchaseUpdatedSubscription = null;
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // prepare
    await FlutterInappPurchase.instance.initConnection;

    if (!mounted) return;

    purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((productItem) {
      print('puelias: $productItem');
      finishPurchase();
    });

    purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen((purchaseError) {
      isLoadingController.add(false);
      print('purchase-error: $purchaseError');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: primaryColor,
        ),
        backgroundColor: defaultBGColor,
        elevation: 0,
        title: Text("Gradely Plus", style: appBarTextTheme),
      ),
      body: iapList.isEmpty && (Platform.isIOS || Platform.isAndroid)
          ? Column(
              children: [
                GradelyLoadingIndicator(),
              ],
            )
          : SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: (() {
                    if (user.gradelyPlus) {
                      return Column(
                        children: [
                          Text("gradely_plus_active_title".tr() +
                              "\n" +
                              "gradely_plus_active_thanks".tr()),
                          SizedBox(
                            height: 50,
                          ),
                          Text(
                            "your_benefits".tr(),
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            decoration: boxDec(),
                            child: Column(
                              children: [
                                Container(
                                  decoration: boxDec(),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.heart,
                                          color: primaryColor,
                                        ),
                                        SizedBox(width: 20),
                                        Text("benefit_support".tr())
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Container(
                                  decoration: boxDec(),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Icon(
                                          FontAwesome5.laugh,
                                          color: primaryColor,
                                        ),
                                        SizedBox(width: 20),
                                        Text("benefit_emojis".tr())
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: boxDec(),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Icon(
                                          FontAwesome5.file_pdf,
                                          color: primaryColor,
                                        ),
                                        SizedBox(width: 20),
                                        Text("benefit_pdf_attachments".tr())
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Container(
                                  decoration: boxDec(),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.star,
                                          color: primaryColor,
                                        ),
                                        SizedBox(width: 20),
                                        Text("benefit_more_coming_soon".tr())
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 50,
                          ),
                          Platform.isIOS || Platform.isAndroid
                              ? Column(children: [
                                  Text(
                                    "gradely_plus_add_tip".tr(),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      gradelyButton(
                                          color: bwColor,
                                          textColor: wbColor,
                                          onPressed: () async {
                                            buyProduct(
                                                "com.eliasschneider.gradely2.iap.gradelyplus");
                                          },
                                          text:
                                              "☕️ ${iapList[0].localizedPrice ?? "-"}"),
                                      gradelyButton(
                                          color: bwColor,
                                          textColor: wbColor,
                                          onPressed: () async => buyProduct(
                                              "com.eliasschneider.gradely2.iap.gradelyplus2"),
                                          text:
                                              "🍺 ${iapList[1].localizedPrice ?? "-"}"),
                                      gradelyButton(
                                          color: bwColor,
                                          textColor: wbColor,
                                          onPressed: () async => buyProduct(
                                              "com.eliasschneider.gradely2.iap.gradelyplus5"),
                                          text:
                                              "🥃 ${iapList[2].localizedPrice ?? "-"}"),
                                    ],
                                  )
                                ])
                              : Text("gradely_plus_mobile_only".tr(),
                                  style: TextStyle(fontStyle: FontStyle.italic))
                        ],
                      );
                    } else {
                      return Column(children: [
                        SizedBox(height: 20),
                        Text(
                          "why_gradely_plus".tr(),
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text("gradely_plus_description".tr()),
                        SizedBox(
                          height: 30,
                        ),
                        Text(
                          "benefits".tr(),
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          decoration: boxDec(),
                          child: Column(
                            children: [
                              Container(
                                decoration: boxDec(),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.heart,
                                        color: primaryColor,
                                      ),
                                      SizedBox(width: 20),
                                      Text("benefit_support".tr())
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Container(
                                decoration: boxDec(),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Icon(
                                        FontAwesome5.laugh,
                                        color: primaryColor,
                                      ),
                                      SizedBox(width: 20),
                                      Text("benefit_emojis".tr())
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                decoration: boxDec(),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Icon(
                                        FontAwesome5.file_pdf,
                                        color: primaryColor,
                                      ),
                                      SizedBox(width: 20),
                                      Text("benefit_pdf_attachments".tr())
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Container(
                                decoration: boxDec(),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.star,
                                        color: primaryColor,
                                      ),
                                      SizedBox(width: 20),
                                      Text("benefit_more_coming_soon".tr())
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        Platform.isIOS || Platform.isAndroid
                            ? Column(children: [
                                Text(
                                  "gradely_plus_explain_products".tr(),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height: 25,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    gradelyButton(
                                        onPressed: () async {
                                          buyProduct(
                                              "com.eliasschneider.gradely2.iap.gradelyplus");
                                        },
                                        text:
                                            "☕️ ${iapList[0].localizedPrice ?? "-"}"),
                                    gradelyButton(
                                        onPressed: () async => buyProduct(
                                            "com.eliasschneider.gradely2.iap.gradelyplus2"),
                                        text:
                                            "🍺 ${iapList[1].localizedPrice ?? "-"}"),
                                    gradelyButton(
                                        onPressed: () async => buyProduct(
                                            "com.eliasschneider.gradely2.iap.gradelyplus5"),
                                        text:
                                            "🥃 ${iapList[2].localizedPrice ?? "-"}"),
                                  ],
                                )
                              ])
                            : Text("gradely_plus_mobile_only".tr(),
                                style: TextStyle(fontStyle: FontStyle.italic))
                      ]);
                    }
                  }())),
            ),
    );
  }
}
