import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(date);

String formatShortDate(BuildContext context, DateTime date) =>
    DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).format(date);
