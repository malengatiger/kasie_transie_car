import 'package:flutter/material.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/utils/functions.dart';

class CarQrcode extends StatelessWidget {
  const CarQrcode({Key? key, required this.vehicle}) : super(key: key);

  final lib.Vehicle vehicle;
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      appBar: AppBar(
        title: Text('Vehicle QR Code', style: myTextStyleLarge(context),),
      ),
      body: Column(
        children: [
          Text('${vehicle.vehicleReg}'),
          const SizedBox(height: 48,),
          Card(
            shape: getRoundedBorder(radius: 16),
            elevation: 8,
            child: Image.network('${vehicle.qrCodeUrl}'),
          )
        ],
      ),
    ));
  }
}
