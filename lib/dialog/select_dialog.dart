import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';

class SelectDialog<T> extends StatelessWidget {

  final String title;

  final List<T> list;

  const SelectDialog({
    super.key,
    required this.title,
    required this.list,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: ScreenPlanner(context).dialogWidth,
        height: MediaQuery.of(context).size.height * 0.7,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            switch(T) {
              case Account:
                return AccountCard(
                  data: item as Account,
                  showBalance: false,
                  onTap: () => Navigator.pop(context, item),
                );
              case Payment:
                return PaymentCard(
                  data: item as Payment,
                  onTap: () => Navigator.pop(context, item),
                );
              default:
                return const SizedBox();
            }
          },
        ),
      ),
    );
  }

}