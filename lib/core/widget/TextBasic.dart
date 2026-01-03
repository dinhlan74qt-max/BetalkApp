import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Text customText({
  required String text, required Color? color, required double? fonSize, required FontWeight? fonWeight
}) {
  return Text(
    text,
    style: TextStyle(
      color: color ?? Colors.black,
      fontSize: fonSize ?? 16,
      fontWeight: fonWeight,
      fontFamily: "InstagramSans",
    ),
    softWrap: true, // Cho phép tự động xuống dòng
    overflow: TextOverflow.visible,
    maxLines: null,
  );
}