import 'package:flutter/material.dart';
import 'package:kasie_transicar/ui/vehicle_list.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lm;
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';

class AssociationList extends StatefulWidget {
  const AssociationList({Key? key}) : super(key: key);

  @override
  AssociationListState createState() => AssociationListState();
}

class AssociationListState extends State<AssociationList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final mm = '🍐🍐🍐🍐AssociationList 🍐🍐';
  var assocList = <lm.Association>[];
  bool busy = false;
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  void _getData() async {
    pp('$mm  ... getting data ....... ');
    setState(() {
      busy = true;
    });
    try {
      assocList = await listApiDog.getAssociations();
      pp('$mm ...... associations found: ${assocList.length}');
    } catch (e) {
      pp(e);
    }

    setState(() {
      busy = false;
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      appBar: AppBar(
        title: Text('Associations', style: myTextStyleLarge(context),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            const SizedBox(height: 48,),
            const Text('Select the association for the taxi'),
            const SizedBox(height: 48,),
            Expanded(
              child: Card(
                shape: getRoundedBorder(radius: 16),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ListView.builder(
                      itemCount: assocList.length,
                      itemBuilder: (ctx,index){
                        final ass = assocList.elementAt(index);
                        return GestureDetector(
                          onTap: (){
                            navigateWithScale(const VehicleList(), context);
                          },
                          child: Card(
                            shape: getRoundedBorder(radius: 16),
                            elevation: 4,
                            child: ListTile(
                              title: Text('${ass.associationName}', style: myTextStyleSmallBold(context),),
                              subtitle: ass.cityName == null? const SizedBox(): Padding(
                                padding: const EdgeInsets.only(top:8.0),
                                child: Text(ass.cityName!, style: myTextStyleTiny(context),),
                              ),
                              leading: Icon(Icons.back_hand, color: Theme.of(context).primaryColor,),
                            ),
                          ),
                        );
                      }),
                ),
              ),
            )
          ],
        ),
      ),
    ));
  }
}
