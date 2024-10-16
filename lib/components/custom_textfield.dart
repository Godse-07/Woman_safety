import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {
  // const CustomTextfield({super.key, this.hintText, this.controller});

  @required
  final String? hintText;

  final TextEditingController? controller;

  String? Function(String?)? validate;

  Function(String?)? onsave;

  final int? maxLines;

  final bool isPassword;

  final bool enable;

  final TextInputType? keyboardType;

  final TextInputAction? textInputAction;

  final FocusNode? focusNode;

  final Widget? prefix;

  final Widget? suffix;

  final bool? check;

  CustomTextfield({
    this.hintText,
    this.controller,
    this.validate,
    this.onsave,
    this.maxLines,
    this.isPassword = false,
    this.enable = true,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.prefix,
    this.suffix,
    this.check,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: enable == true ? true : enable,
      maxLength: maxLines == null ? null : maxLines,
      onSaved: onsave,
      focusNode: focusNode,
      textInputAction: textInputAction,
      keyboardType: keyboardType == null ? TextInputType.name : keyboardType,
      controller: controller,
      validator: validate,
      obscureText: isPassword == false ? false : isPassword,
      decoration: InputDecoration(
        prefixIcon: prefix,
        suffixIcon: suffix,
        hintText: hintText ?? "Hint Text..",
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              style: BorderStyle.solid,
              color: Theme.of(context).primaryColor,
            )),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            style: BorderStyle.solid,
            color: Color(0xFF909A9E),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            style: BorderStyle.solid,
            color: Theme.of(context).primaryColor,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            style: BorderStyle.solid,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
