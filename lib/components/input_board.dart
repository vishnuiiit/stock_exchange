import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:stockexchange/global.dart';
import 'package:stockexchange/components/dialogs/common_alert_dialog.dart';

class TextEditingControllerWorkaround extends TextEditingController {
  TextEditingControllerWorkaround({String text}) : super(text: text);

  void setTextAndPosition(String newText, {int caretPosition}) {
    int offset = caretPosition != null ? caretPosition : newText.length;
    value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: offset),
        composing: TextRange.empty);
  }
}

extension setText on TextEditingController {
  set newText(String text) {
    this.text = text;
    this.selection =
        TextSelection.fromPosition(TextPosition(offset: this.text.length));
  }
}

class InputBoardSpecs {
  String value; //do not use
  List<TextEditingControllerWorkaround> inputTextControllers = [];
  String dropDownValue;
  final State<InputBoard> state;
  List<String> errorText = [];
  List<String> infoText = [];

  InputBoardSpecs(this.state, this.dropDownValue);

  ///if [nullIfEmpty] is true than return null in case of any empty field,
  ///Otherwise it returns 0 in case of empty field.
  ///
  /// Note:- always returns null in case of text == ' '.
  int getTextFieldIntValue(int index, {bool nullIfEmpty = false}) {
    if(nullIfEmpty && inputTextControllers[index].text == null)
      return null;
    int result;
    try {
      String text = inputTextControllers[index].text;
      result = text != '' ? int.parse(text) : null;
    } catch (error) {
      log('err: $error', name: getTextFieldIntValue.toString());
      result = 0;
      setBoardState(() {
        inputTextControllers[index].text = "";
      });
    }
    return result;
  }

  List<int> getAllTextFieldIntValues() {
    List<int> inputValues = [];
    inputValues.length = inputTextControllers.length;
    for (int i = 0; i < inputValues.length; i++) {
      inputValues[i] = getTextFieldIntValue(i);
    }
    return inputValues;
  }

  void setAllFieldsText(List<String> texts) {
    assert(texts.length >= inputTextControllers.length);
    for(int i = 0; i < inputTextControllers.length; i++)
      inputTextControllers[i].newText = texts[i];
  }

  void setFieldText(int index, String text) =>
      inputTextControllers[index].newText = text;

  void clearAllTextFields() {
    for (TextEditingController controller in inputTextControllers)
      controller.text = "";
  }

  ///here company is assumed to be set by dropDownValue
  void checkAndTakeActionIfCompanyIsBankrupt(BuildContext context) {
    String companyName = dropDownValue;
    if (getCompany(companyName).getCurrentSharePrice().toInt() == 0) {
      log("Company is Bankrupt",
          name: checkAndTakeActionIfCompanyIsBankrupt.toString());
      errorText.length = inputTextControllers.length;
      setBoardState(() {
        errorText.last = "Company is Bankrupt";
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return CommonAlertDialog("Company is Bankrupt",
                  icon: Icon(
                    Icons.block,
                    color: Colors.redAccent,
                  ));
            });
      });
      return;
    }
  }

  Future<bool> checkAndTakeActionIfAllFieldsAreEmpty(context) async {
    int totalFields = inputTextControllers.length;
    if (totalEmptyFields() == totalFields) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return CommonAlertDialog(
              "All Fields are Empty",
              icon: Icon(Icons.block, color: Colors.red),
            );
          });
      return true;
    }
    return false;
  }

  int totalEmptyFields() {
    int result = 0;
    for (TextEditingController input in inputTextControllers)
      if (input.text == '') result++;
    return result;
  }

  void showInfo(List<String> infoText) {
    clearErrors();
    setBoardState(() {
      this.infoText = infoText;
    });
    infoText = [];
  }

  void clearErrors() {
    errorText = [];
    errorText.length = inputTextControllers.length;
    showAllErrors(errorText);
  }

  void showAllErrors(List<String> errorText) {
    setBoardState(() {
      this.errorText = errorText;
    });
  }

  void showError(int index, String errorText) {
    setBoardState(() {
      this.errorText[index] = errorText;
    });
  }
  // ignore: invalid_use_of_protected_member
  void setBoardState(Function fn) => state.setState(fn);
}

class InputBoard extends StatefulWidget {
  final List<String> dropDownList;
  final Key keyThis;
  final String initialDropDownValue;
  final List<Function(InputBoardSpecs)> inputOnChanged;
  final List<Function(InputBoardSpecs)> inputOnSubmitted;
  final Function(InputBoardSpecs) onPressedButton;
  final List<String> inputText;
  final List<Widget> textPrefix;
  final List<String> errorText;
  final buttonText;
  final totalTextFields;
  final showDropDownMenu;
  final sliverListType;
  final List<TextInputType> inputType;

  InputBoard({
    this.keyThis,
    @required this.dropDownList,
    this.initialDropDownValue,
    this.onPressedButton,
    this.buttonText: "SUBMIT",
    this.totalTextFields: 2,
    this.errorText,
    this.inputOnChanged: const [],
    this.inputOnSubmitted: const [],
    this.inputType: const [],
    this.textPrefix: const [],
    this.showDropDownMenu: true,
    this.inputText: const [
      "Number of Shares",
      "Price",
    ],
    this.sliverListType: true,
  }) : super(key: keyThis);

  @override
  _InputBoardState createState() =>
      _InputBoardState(initialDropDownValue, errorText);
}

class _InputBoardState extends State<InputBoard> {
  String dropDownValue;

//  List<TextEditingControllerWorkaround> inputTextController = [];
  InputBoardSpecs _specs;

  _InputBoardState(this.dropDownValue, errorText) {
    _specs = InputBoardSpecs(this, dropDownValue);
    if (errorText != null) _specs.errorText = errorText;
  }

  @override
  @protected
  Widget build(BuildContext context) {
    if (!widget.dropDownList.contains(_specs.dropDownValue) &&
        widget.showDropDownMenu) _specs.dropDownValue = widget.dropDownList[0];
    if (_specs.inputTextControllers.length != widget.totalTextFields) {
      _specs.inputTextControllers.length = widget.totalTextFields;
      log("total input controllers changed to: ${widget.totalTextFields}",
          name: 'InputBoard');
      for (int i = 0; i < widget.totalTextFields; i++) {
        _specs.inputTextControllers[i] = TextEditingControllerWorkaround();
        _specs.errorText.length = _specs.inputTextControllers.length;
      }
    }

    Container mainBoard = Container(
      margin: EdgeInsets.only(left: 10, right: 10, bottom: 30, top: 5),
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      decoration: kSlateBackDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          widget.showDropDownMenu
              ? DropdownButton<String>(
                  value: _specs.dropDownValue ?? widget.initialDropDownValue,
                  items: widget.dropDownList
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      log("changing drop down value to: $value",
                          name: 'InputBoard');
                      _specs.dropDownValue = value;
                    });
                  },
                )
              : SizedBox(),
          SizedBox(
            height: 20,
          ),
          Column(
            children: _allTextFields(),
          ),
          RaisedButton(
            child: Text(
              widget.buttonText,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: widget.onPressedButton != null
                ? () {
                    widget.onPressedButton(_specs);
                  }
                : null,
          ),
        ],
      ),
    );

    if (widget.sliverListType) {
      return SliverList(
        delegate: SliverChildListDelegate(
          [
            mainBoard,
          ],
        ),
      );
    }
    return mainBoard;
  }

  List<Widget> _allTextFields() {
    List<TextInputType> inputType = [];
    for (int i = 0; i < widget.totalTextFields; i++) {
      if (i < widget.inputType.length)
        inputType.add(widget.inputType[i] ?? TextInputType.number);
      else
        inputType.add(TextInputType.number);
    }
    List<Widget> result = [];
    for (int i = 0; i < widget.totalTextFields; i++) {
      result.add(
        TextField(
          controller: _specs.inputTextControllers[i],
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            prefix: widget.textPrefix.length > i ? widget.textPrefix[i] : null,
            labelText: widget.inputText[i],
            labelStyle: TextStyle(
              fontSize: screenWidth * 0.045,
            ),
          ),
          keyboardType: inputType[i] ?? TextInputType.number,
          onChanged: (value) {
            _specs.value = value;
            if (widget.inputOnChanged[i] != null)
              widget.inputOnChanged[i](_specs);
          },
          onSubmitted: (value) {
            _specs.value = value;
            if (widget.inputOnSubmitted[i] != null)
              widget.inputOnSubmitted[i](_specs);
          },
        ),
      );
      result.add(
        SizedBox(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _specs.errorText.length > i
                          ? _specs.errorText[i] ?? ""
                          : "",
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Text(
                    _specs.infoText.length > i ? _specs.infoText[i] ?? "" : "",
                    style: TextStyle(
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return result;
  }
}
