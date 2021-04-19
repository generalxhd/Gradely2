import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'main.dart';
import 'package:flutter/material.dart';
import 'data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'userAuth/login.dart';
import 'chooseSemester.dart';
import 'data.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'shared/defaultWidgets.dart';
import 'dart:async';
import 'package:gradely/semesterDetail.dart';
import 'package:easy_localization/easy_localization.dart';

String selectedTest = "selectedTest";
String errorMessage = "";
double averageOfTests = 0;
List testListID = [];
num _sumW = 0;
num _sum = 0;
var defaultBGColor;
TextEditingController editTestInfoName = new TextEditingController();
TextEditingController editTestInfoGrade = new TextEditingController();
TextEditingController editTestInfoWeight = new TextEditingController();

class LessonsDetail extends StatefulWidget {
  @override
  _LessonsDetailState createState() => _LessonsDetailState();
}

class _LessonsDetailState extends State<LessonsDetail> {
  _getTests() async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection(
            'userData/${auth.currentUser.uid}/semester/$choosenSemester/lessons/$selectedLesson/grades')
        .get();
    List<DocumentSnapshot> documents = result.docs;
    setState(() {
      testList = [];
      testListID = [];
      documents.forEach((data) => testListID.add(data.id));
      documents.forEach((data) => testList.add(data["name"]));
    });
  }

  darkModeColorChanger() {
    var brightness = MediaQuery.of(context).platformBrightness;
    if (brightness == Brightness.dark) {
      setState(() {
        bwColor = Colors.grey[850];
        wbColor = Colors.white;
        defaultBGColor = Colors.grey[900];
      });
    } else {
      bwColor = Colors.white;
      wbColor = Colors.grey[850];
      defaultBGColor = Colors.grey[300];
    }
  }

  List averageList = [];
  List averageListWeight = [];
  getTestAvarage() async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection(
            'userData/${auth.currentUser.uid}/semester/$choosenSemester/lessons/$selectedLesson/grades')
        .get();

    List<DocumentSnapshot> documents = result.docs;
    setState(() {
      averageList = [];
      documents.forEach((data) {
        double _averageSum;

        _averageSum = data["grade"] * data["weight"];
        averageList.add(_averageSum);
        averageListWeight.add(data["weight"]);
      });
    });
    _sumW = 0;
    _sum = 0;

    for (num e in averageListWeight) {
      _sumW += e;
    }

    for (num e in averageList) {
      _sum += e;
    }
    setState(() {
      averageOfTests = _sum / _sumW;
    });

    FirebaseFirestore.instance
        .collection('userData')
        .doc(auth.currentUser.uid)
        .collection('semester')
        .doc(choosenSemester)
        .collection('lessons')
        .doc(selectedLesson)
        .update({"average": averageOfTests});
  }

  void initState() {
    super.initState();

    getChoosenSemester();
    _getTests();
    getTestAvarage();
  }

  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    getPluspoints(averageOfTests);
    darkModeColorChanger();
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeWrapper()),
                  (Route<dynamic> route) => false,
                );
              }),
          title: Text(selectedLessonName),
          shape: defaultRoundedCorners(),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: testList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(8, 6, 8, 0),
                    child: Container(
                      decoration: boxDec(),
                      child: Slidable(
                        actionPane: SlidableDrawerActionPane(),
                        actionExtentRatio: 0.25,
                        secondaryActions: <Widget>[
                          IconSlideAction(
                            caption: 'löschen'.tr(),
                            color: Colors.red,
                            icon: Icons.delete,
                            onTap: () {
                              _getTests();

                              selectedTest = testListID[index];
                              FirebaseFirestore.instance
                                  .collection(
                                      'userData/${auth.currentUser.uid}/semester/$choosenSemester/lessons/$selectedLesson/grades')
                                  .doc(selectedTest)
                                  .set({});
                              FirebaseFirestore.instance
                                  .collection(
                                      'userData/${auth.currentUser.uid}/semester/$choosenSemester/lessons/$selectedLesson/grades')
                                  .doc(selectedTest)
                                  .delete();
                              HapticFeedback.mediumImpact();
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (context, animation1, animation2) =>
                                          LessonsDetail(),
                                  transitionDuration: Duration(seconds: 0),
                                ),
                              );
                            },
                          ),
                        ],
                        child: ListTile(
                            title: Text(
                              testList[index],
                            ),
                            subtitle: averageList.isEmpty
                                ? Text("")
                                : Row(
                                    children: [
                                      Icon(
                                        Icons.calculate_outlined,
                                        size: 20,
                                      ),
                                      Text(
                                        " " +
                                            averageListWeight[index].toString(),
                                      ),
                                    ],
                                  ),
                            trailing: Text(
                              (averageList[index] / averageListWeight[index])
                                  .toString(),
                            ),
                            onTap: () async {
                              _getTests();

                              selectedTest = testListID[index];

                              testDetails = (await FirebaseFirestore.instance
                                      .collection(
                                          "userData/${auth.currentUser.uid}/semester/$choosenSemester/lessons/$selectedLesson/grades")
                                      .doc(selectedTest)
                                      .get())
                                  .data();

                              testDetail(context);
                            }),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: bwColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 30),
                child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      gradesResult == "Pluspunkte"
                          ? Column(
                              children: [
                                Text(
                                  plusPoints.toString(),
                                  style: TextStyle(fontSize: 17),
                                ),
                                Text(
                                  (() {
                                    if (averageOfTests.isNaN) {
                                      return "-";
                                    } else {
                                      return averageOfTests.toStringAsFixed(2);
                                    }
                                  })(),
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 10),
                                ),
                              ],
                            )
                          : Text((() {
                              if (averageOfTests.isNaN) {
                                return "-";
                              } else {
                                return averageOfTests.toStringAsFixed(2);
                              }
                            })(), style: TextStyle(fontSize: 17)),
                      IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            addTest(context);
                            HapticFeedback.lightImpact();
                          }),
                      IconButton(
                          icon: FaIcon(FontAwesomeIcons.calculator, size: 17),
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation1, animation2) =>
                                        DreamGradeC(),
                                transitionDuration: Duration(seconds: 0),
                              ),
                            );
                            HapticFeedback.lightImpact();
                          }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Future testDetail(BuildContext context) {
    editTestInfoGrade.text = testDetails["grade"].toString();
    editTestInfoName.text = testDetails["name"];
    editTestInfoWeight.text = testDetails["weight"].toString();
    return showCupertinoModalBottomSheet(
      backgroundColor: defaultBGColor,
      expand: true,
      context: context,
      builder: (context) => SingleChildScrollView(
          controller: ModalScrollController.of(context),
          child: Material(
            color: defaultBGColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 60, 0, 0),
                    child: Text(
                      testDetails["name"],
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(
                      thickness: 2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: editTestInfoName,
                      textAlign: TextAlign.left,
                      decoration: inputDec("Test Name".tr()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: editTestInfoGrade,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.left,
                      decoration: inputDec("Note".tr()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: editTestInfoWeight,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.left,
                      decoration: inputDec("Gewichtung".tr()),
                    ),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection(
                                'userData/${auth.currentUser.uid}/semester/$choosenSemester/lessons/$selectedLesson/grades')
                            .doc(selectedTest)
                            .set({
                          "name": editTestInfoName.text,
                          "grade": double.parse(
                            editTestInfoGrade.text.replaceAll(",", "."),
                          ),
                          "weight": double.parse(
                              editTestInfoWeight.text.replaceAll(",", "."))
                        });
                        HapticFeedback.mediumImpact();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LessonsDetail()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Text("Test updaten".tr())),
                  SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection(
                                'userData/${auth.currentUser.uid}/semester/$choosenSemester/lessons/$selectedLesson/grades')
                            .doc(selectedTest)
                            .set({});
                        FirebaseFirestore.instance
                            .collection(
                                'userData/${auth.currentUser.uid}/semester/$choosenSemester/lessons/$selectedLesson/grades')
                            .doc(selectedTest)
                            .delete();
                        HapticFeedback.mediumImpact();
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation1, animation2) =>
                                LessonsDetail(),
                            transitionDuration: Duration(seconds: 0),
                          ),
                        );
                      },
                      child: Text("Test löschen".tr()))
                ],
              ),
            ),
          )),
    );
  }
}

Future addTest(BuildContext context) {
  addTestNameController.text = "";
  addTestGradeController.text = "";
  addTestWeightController.text = "1";

  return showCupertinoModalBottomSheet(
    expand: true,
    context: context,
    builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: Material(
          color: defaultBGColor,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 60, 0, 0),
                    child: Text(
                      "Test hinzufügen".tr(),
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(
                      thickness: 2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                        controller: addTestNameController,
                        textAlign: TextAlign.left,
                        decoration: inputDec("Test Name".tr())),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                        controller: addTestGradeController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.left,
                        decoration: inputDec("Note".tr())),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                        controller: addTestWeightController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.left,
                        decoration: inputDec("Gewichtung".tr())),
                  ),
                  ElevatedButton(
                    child: Text("Test hinzufügen".tr()),
                    onPressed: () {
                      bool isNumeric() {
                        if (addTestGradeController.text == null) {
                          return false;
                        }
                        return double.tryParse(addTestGradeController.text) !=
                            null;
                      }

                      if (isNumeric() == false) {
                        errorMessage = "Bitte eine gültige Note eingeben.";

                        Future.delayed(Duration(seconds: 4))
                            .then((value) => {errorMessage = ""});
                      }

                      createTest(
                        addTestNameController.text,
                        double.parse(
                            addTestGradeController.text.replaceAll(",", ".")),
                        double.parse(
                            addTestWeightController.text.replaceAll(",", ".")),
                      );

                      addLessonController.text = "";
                      courseList = [];
                      HapticFeedback.lightImpact();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LessonsDetail()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                  Text(errorMessage)
                ],
              )),
        )),
  );
}

createTest(String testName, double grade, double weight) {
  FirebaseFirestore.instance
      .collection('userData')
      .doc(auth.currentUser.uid)
      .collection('semester')
      .doc(choosenSemester)
      .collection('lessons')
      .doc(selectedLesson)
      .collection('grades')
      .doc()
      .set({"name": testName, "grade": grade, "weight": weight});
}

class DreamGradeC extends StatefulWidget {
  @override
  _DreamGradeCState createState() => _DreamGradeCState();
}

class _DreamGradeCState extends State<DreamGradeC> {
  num dreamgradeResult = 0;
  double dreamgrade = 0;
  double dreamgradeWeight = 1;

  getDreamGrade() {
    setState(() {
      dreamgradeResult =
          ((dreamgrade * (_sumW + dreamgradeWeight) - _sum) / dreamgradeWeight);
    });
  }

  @override
  @override
  void initState() {
    super.initState();
    dreamGradeGrade.text = "";
    dreamGradeWeight.text = "1";
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("dream grade calculator".tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            SizedBox(
              height: 50,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: dreamGradeGrade,
                onChanged: (String value) async {
                  dreamgrade = double.tryParse(
                      dreamGradeGrade.text.replaceAll(",", "."));
                  getDreamGrade();
                },
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.left,
                decoration: inputDec("dream grade".tr()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: dreamGradeWeight,
                onChanged: (String value) async {
                  dreamgradeWeight = double.tryParse(
                      dreamGradeWeight.text.replaceAll(",", "."));
                  getDreamGrade();
                },
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.left,
                decoration: inputDec("dream grade weight".tr()),
              ),
            ),
            SizedBox(
              height: 25,
            ),
            Row(
              children: [
                Text("dreamGrade1".tr()),
                Text((() {
                  if (dreamgradeResult.isInfinite) {
                    return "-";
                  } else {
                   return dreamgradeResult.toStringAsFixed(2);
                  }
                })(), style: TextStyle(fontSize: 20)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
