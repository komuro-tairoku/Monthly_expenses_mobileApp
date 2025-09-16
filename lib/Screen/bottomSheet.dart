import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';

class bottomSheet extends StatefulWidget {
  const bottomSheet({super.key});

  @override
  State<bottomSheet> createState() => _bottomSheetState();
}

class _bottomSheetState extends State<bottomSheet> {
  int value = 0;
  final List<String> chiOptions = [
    "Phương tiện",
    "Mua sắm",
    "Đồ ăn",
    "Giải trí",
  ];
  final List<String> thuOptions = ["Tiền lương", "Phụ cấp", "Tiền thưởng"];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: const BoxDecoration(color: Color(0xFF6B43FF)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 50,
                    child: Column(
                      children: [
                        const Text(
                          'Thêm Thu-Chi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AnimatedToggleSwitch<int>.size(
                          animationDuration: Duration(milliseconds: 300),
                          current: value,
                          values: const [0, 1],
                          indicatorSize: const Size(100, 35),
                          iconOpacity: 1,
                          borderWidth: 5,
                          style: ToggleStyle(
                            borderColor: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            indicatorColor: Colors.grey.shade300,
                          ),
                          styleBuilder: (i) => ToggleStyle(
                            indicatorColor: i == 0
                                ? Colors.green[600]
                                : Colors.green[600],
                          ),
                          iconBuilder: (i) {
                            return Center(
                              child: Text(
                                i == 0 ? "Tiền Chi" : "Tiền Thu",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: value == i
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                          onChanged: (i) => setState(() => value = i),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    left: 0,
                    top: 30,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 25,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
