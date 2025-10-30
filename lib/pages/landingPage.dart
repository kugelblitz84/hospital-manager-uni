import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/Providers/UserProvides.dart';
import 'package:medicare/services/generalServices.dart';

class LandingPage extends ConsumerWidget {
  LandingPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = GeneralServices.initUser() as Map<String, dynamic>;
    return Placeholder();
  }
}
