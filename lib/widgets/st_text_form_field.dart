import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:om_ai/resources/st_colors.dart';
import 'package:om_ai/resources/st_styles.dart';

class StTextFormField extends StatefulWidget {
  // final String label;
  final TextEditingController? controller;
  final IconData? suffixIcon;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldSetter<String>? onSaved;
  final GestureTapCallback? suffixIconOnTap;
  final bool? obscure;
  final FocusNode? focusNode;
  final Color? suffixIconColor;
  final GestureTapCallback? onTap;
  final int? maxLength;
  final bool? enabled;
  final String? prefixText;
  final TextCapitalization textCapitalization;
  final String? suffixText;
  final bool? obscureText; // Make obscureText optional

  // final TextStyle? style;

  const StTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    // required this.label,
    this.validator,
    this.suffixIcon,
    this.onSaved,
    this.focusNode,
    this.inputFormatters,
    this.onChanged,
    this.prefixIcon,
    this.suffixIconOnTap,
    this.obscure = false,
    this.suffixIconColor,
    this.maxLength,
    this.enabled,
    this.onTap,
    this.prefixText,
    this.suffixText,
    // this.style = StStyles.titleText,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText,
  });

  @override
  State<StTextFormField> createState() => StTextFormFieldState();
}

class StTextFormFieldState extends State<StTextFormField> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SizedBox(
        //   height: 46,
        //   child: Align(
        //     alignment: Alignment.centerLeft,
        //     child: Text(widget.label, style: widget.style),
        //   ),
        // ),
        // const SizedBox(height: 8),
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          autofocus: false,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          onChanged: widget.onChanged,
          onSaved: widget.onSaved,
          focusNode: widget.focusNode,
          cursorColor: StColors.stOrange,
          controller: widget.controller,
          obscureText: widget.obscureText ?? false,
          validator: widget.validator,
          onTap: widget.onTap,
          inputFormatters: widget.inputFormatters,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              enabledBorder: StStyles.outLineBorder,
              focusedBorder: StStyles.outLineBorder,
              border: StStyles.outLineBorder,
              hintText: widget.hintText,
              prefixText: widget.prefixText,
              prefixStyle: StStyles.boldText15,
              suffixText: widget.suffixText,
              suffixStyle: StStyles.boldText15,
              prefixIcon:
                  widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
              suffixIcon: widget.suffixIcon != null
                  ? IconButton(
                      onPressed: widget.suffixIconOnTap,
                      icon: Icon(widget.suffixIcon,
                          color: widget.suffixIconColor),
                    )
                  : null),
        ),
      ],
    );
  }
}
