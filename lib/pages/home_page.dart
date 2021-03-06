import 'dart:async';
import 'dart:developer';

import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:stockexchange/components/components.dart';
import 'package:flutter/material.dart';
import 'package:stockexchange/components/dialogs/boolean_dialog.dart';
import 'game_finished_page.dart';
import 'package:stockexchange/global.dart';
import 'package:stockexchange/menu_pages/menu_pages.dart';
import 'package:stockexchange/menu_pages/processed_cards_page.dart';
import 'package:stockexchange/network/network.dart';
import 'package:stockexchange/network/offline_database.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool runCheckAlert = true;
  StreamSubscription connection;
  StreamSubscription alertDialogSubscription;

  @override
  void dispose() async {
    super.dispose();
    if (Network.alertDocSubscription != null)
      await Network.alertDocSubscription.cancel();
    await connection.cancel();
    if (alertDialogSubscription != null) await alertDialogSubscription.cancel();
    currentPage.value = StockPage.start;
    if (!gameFinished) resetAllValues();
  }

  @override
  void initState() {
    super.initState();
    connection = DataConnectionChecker().onStatusChange.listen((event) {
      if (event == DataConnectionStatus.disconnected && online)
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => CommonAlertDialog(
            'NO INTERNET CONNECTION',
            icon: Icon(
              Icons.block,
              color: Colors.red,
              size: 25,
            ),
          ),
        );
    });
    Phone.getGame().then((gameExists) {
      if (gameExists) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => BooleanDialog(
              'Do you want to continue saved game',
              onPressedYes: () {
                startSavedGame();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ifGameFinished();
                });
                Navigator.of(context).pop();
              },
            ),
          );
        });
      } else
        log('game not saved', name: initState.toString());
    });
    if (alertDialogSubscription == null)
      alertDialogSubscription = showAlerts(context);
    log("afterShowAlerts", name: "checkAndShowAlert");
  }

  @override
  Widget build(BuildContext context) {
    homePageState = this;
    screen = MediaQuery.of(context);
    if (screen.orientation == Orientation.portrait) {
      screenWidth = screen.size.width;
      screenHeight = screen.size.height;
    } else {
      screenWidth = screen.size.height;
      screenHeight = screen.size.width;
    }
    return Container(
      key: homePageGlobalKey,
      decoration: BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: screen.orientation == Orientation.portrait
              ? AssetImage("images/back4.jpg")
              : AssetImage("images/back.jpg"),
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Scaffold(
        body: Container(
          child: CustomScrollView(
            slivers: <Widget>[
              backButtonActions(context),
              ValueListenableBuilder(
                valueListenable: currentPage,
                builder: (context, value, _) {
                  if (value == StockPage.home) {
                    fromCompanyPage = false;
                    return ValueListenableBuilder(
                      valueListenable: homeListChanged,
                      builder: (context, value, _) {
                        return SliverList(
                          delegate: SliverChildListDelegate(
                            homeList(),
                          ),
                        );
                      },
                    );
                  } else if (value == StockPage.cards) {
                    return ProcessedCardsPage();
                  } else if (value == StockPage.buy) {
                    log("changing to StockPage.buy", name: 'homePage');
                    return ShareMarket.buyPage(context);
                  } else if (value == StockPage.sell) {
                    log("changing to StockPage.sell", name: 'homePage');
                    return ShareMarket.sellPage(context);
                  } else if (value == StockPage.trade) {
                    return TradePage();
                  } else if (value == StockPage.buyCards) {
                    return BuyCardsPage();
                  } else if (value == StockPage.barChart)
                    return AllSharesBarChartMenu();
                  else if (value == StockPage.totalAssets)
                    return TotalAssetsMenuPage();
                  else if (value == StockPage.start)
                    return StartingPage();
                  else
                    return NextRoundPage();
                },
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

List<Widget> homeList() {
  List<Widget> result = [];
  for (int i = 0; i < companies.length; i++) {
    List<double> temp = companies[i].getAllSharePrice();
    result.add(CompanySlates(
      currentCompany: companies[i],
      sharePriceChange:
          temp.length >= 2 ? temp.last - temp[temp.length - 2] : 0,
    ));
  }
  return result;
}
