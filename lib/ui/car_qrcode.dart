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
          const SizedBox(height: 48,),
          Text('${vehicle.vehicleReg}',
            style: myTextStyleMediumLargeWithColor(context, Theme.of(context).primaryColor, 32),),
          const SizedBox(height: 8,),
          Text('${vehicle.associationName}', style: myTextStyleSmall(context),),
          const SizedBox(height: 48,),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                shape: getRoundedBorder(radius: 16),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network('${vehicle.qrCodeUrl}',
                  height: 400, width: 400,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    ));
  }
}
