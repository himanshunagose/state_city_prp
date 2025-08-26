import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;


class CountryStateCityPicker extends StatefulWidget {
  final TextEditingController state;
  final TextEditingController city;
  final InputDecoration? textFieldDecoration;

  const CountryStateCityPicker({
    super.key,
    required this.state,
    required this.city,

    this.textFieldDecoration,
  });

  @override
  State<CountryStateCityPicker> createState() => CountryStateCityPickerState();
}

class CountryStateCityPickerState extends State<CountryStateCityPicker> {
  List<StateModel> _stateList = [];
  List<CityModel> _cityList = [];

  List<StateModel> _filteredStateList = [];
  List<CityModel> _filteredCityList = [];

  final LayerLink _stateLayerLink = LayerLink();
  final LayerLink _cityLayerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _setDefaultCountry();

  }
  bool validateFields() {
    bool isValid = true;

    setState(() {
      _stateityerror = widget.state.text.trim().isEmpty;
      _showcityerror = widget.city.text.trim().isEmpty;
    });

    if (_stateityerror || _showcityerror) {
      isValid = false;
    }

    return isValid;
  }



  void _setDefaultCountry() async {
    await _getState("101"); // Assuming India's ID is "101"
  }

  Future<void> _getState(String countryId) async {
    var jsonString = await rootBundle.loadString('packages/country_state_city_pro/assets/state.json');
    List<dynamic> body = json.decode(jsonString);
    setState(() {
      _stateList = body
          .map((dynamic item) => StateModel.fromJson(item))
          .where((element) => element.countryId == countryId)
          .toList();
      _filteredStateList = _stateList;
    });
  }

  Future<void> _getCity(String stateId) async {
    var jsonString = await rootBundle.loadString('packages/country_state_city_pro/assets/city.json');
    List<dynamic> body = json.decode(jsonString);
    setState(() {
      _cityList = body
          .map((dynamic item) => CityModel.fromJson(item))
          .where((element) => element.stateId == stateId)
          .toList();
      _filteredCityList = _cityList;
    });
  }

  void removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDropdown(
      BuildContext context,
      LayerLink layerLink,
      List<dynamic> items,
      TextEditingController controller,
      Function(String) onSelect,
      ) {
    removeOverlay();
    // if (items.isEmpty) return;

    OverlayState overlayState = Overlay.of(context);
    _overlayEntry = _createOverlayEntry(context, layerLink, items, controller, onSelect);
    overlayState.insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry(
      BuildContext context,
      LayerLink layerLink,
      List<dynamic> items,
      TextEditingController controller,
      Function(String) onSelect) {

    // Get the width of the TextField dynamically
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    double textFieldWidth =
        renderBox?.size.width ?? MediaQuery.of(context).size.width * 0.8;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          removeOverlay();
          controller.clear(); // Clear the controller when closing
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: textFieldWidth, // ✅ Dynamic width of dropdown
              child: CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 50),
                child: Material(
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    constraints: BoxConstraints(
                      maxWidth: textFieldWidth, // ✅ Apply maxWidth dynamically
                      maxHeight: 300,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowIndicator();
                        return true;
                      },
                      child:items.isEmpty  ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No result found',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                        : ListView.builder(
                padding: EdgeInsets.only(top: 10),
                shrinkWrap: true,
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  String name = items[index].name;
                  return ListTile(
                    title: Text(name),
                    onTap: () {
                      onSelect(name);
                      removeOverlay(); // ✅ Close overlay on item selection
                    },
                  );
                },
              ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  bool _showCityError = false;
  bool _showcityerror=false;
  bool _stateityerror=false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column( crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(elevation: 5,
            child: CompositedTransformTarget(
              link: _stateLayerLink,
              child: TextField(
                onTap: () {
                  _showDropdown(context, _stateLayerLink, _filteredStateList, widget.state, (value) {
                    setState(() {
                      widget.state.text = value.trim();
                      _getCity(
                        _filteredStateList.firstWhere(
                              (element) => element.name.trim() == value.trim(),
                        ).id,
                      );
                      widget.city.clear(); // Clear city when state changes
                    });
                  });
                },
                controller: widget.state,
                /* onChanged: (val) {
                  setState(() {
                    _filteredStateList = _stateList.where(
                          (element) => element.name.toLowerCase().contains(val.toLowerCase()),
                    ).toList();
                  });
                  _showDropdown(context, _stateLayerLink, _filteredStateList, widget.state, (value) {
                    setState(() {
                      widget.state.text = value;
                      _getCity(_filteredStateList.firstWhere((element) => element.name == value).id);
                      widget.city.clear(); // Clear city when state changes
                    });
                  });
                },*/
                onChanged: (val) {
                  setState(() {
                    _filteredStateList = _stateList.where(
                          (element) =>
                          element.name.toLowerCase().trim().contains(val.toLowerCase().trim()),
                    ).toList();
                    _stateityerror = val.trim().isEmpty;
                  });

                  _showDropdown(context, _stateLayerLink, _filteredStateList, widget.state, (value) {
                    setState(() {
                      widget.state.text = value.trim();
                      _showcityerror=false;
                      _getCity(
                        _filteredStateList.firstWhere(
                              (element) => element.name.trim() == value.trim(),
                        ).id,
                      );
                      widget.city.clear(); // Clear city when state changes
                    });
                  });
                },

                decoration: widget.textFieldDecoration?.copyWith(hintText: 'Enter state',
                  errorText: _stateityerror?"Please enter state":null,) ??
                    InputDecoration(
                      errorText: _stateityerror?"Please enter state":null,
                      labelText: 'Enter state',
                      border: OutlineInputBorder(),
                    ),
              ),
            ),
          ),

          SizedBox(height: 5),
          Card(elevation: 5,
            child: CompositedTransformTarget(
              link: _cityLayerLink,
              child: TextField(
                readOnly: widget.state.text.trim().isEmpty,
                onTap: () {
                  if (widget.state.text.trim().isEmpty) {
                    setState(() {
                      _showCityError = true;
                      _showcityerror=true;
                    });
                    return;
                  }

                  setState(() {
                    _showCityError = false;
                    _showcityerror=false;
                  });

                  final trimmedStateName = widget.state.text.trim();
                  final selectedState = _filteredStateList.firstWhere(
                        (element) => element.name.trim() == trimmedStateName,
                    orElse: () => StateModel(id: '', name: '', countryId: ''),
                  );

                  if (selectedState.id.isNotEmpty) {
                    _getCity(selectedState.id);
                    _showDropdown(context, _cityLayerLink, _filteredCityList, widget.city, (value) {
                      setState(() {
                        widget.city.text = value.trim();
                      });
                    });
                  }
                },
                controller: widget.city,
                onChanged: (val) {
                  final trimmedVal = val.trim();
                  final trimmedStateName = widget.state.text.trim();

                  if (trimmedStateName.isNotEmpty) {
                    final selectedState = _filteredStateList.firstWhere(
                          (element) => element.name.trim() == trimmedStateName,
                      orElse: () => StateModel(id: '', name: '', countryId: ''),
                    );

                    if (selectedState.id.isNotEmpty) {
                      setState(() {
                        _showCityError = false;
                        _showcityerror=false;
                        _getCity(selectedState.id);
                        _filteredCityList = _cityList.where(
                              (element) => element.name.toLowerCase().trim().contains(trimmedVal.toLowerCase()),
                        ).toList();
                      });

                      _showDropdown(context, _cityLayerLink, _filteredCityList, widget.city, (value) {
                        setState(() {
                          widget.city.text = value.trim();
                        });
                      });
                    }
                  }
                },
                decoration: widget.textFieldDecoration?.copyWith(errorText: _showcityerror ?"Please enter city":null,
                  labelText: 'Enter city',
                ) ??
                     InputDecoration( errorText: _showcityerror ?"Please enter city":null,
                      hintText: 'Enter city',
                      border: OutlineInputBorder(),
                    ),
              ),
            ),
          ),

          if (_showCityError)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 10),
              child: Text(
                'Please select a state first',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// **Models**
class StateModel {
  final String id;
  final String name;
  final String countryId;

  StateModel({required this.id, required this.name, required this.countryId});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'].toString(),
      name: json['name'],
      countryId: json['country_id'].toString(),
    );
  }
}

class CityModel {
  final String id;
  final String name;
  final String stateId;

  CityModel({required this.id, required this.name, required this.stateId});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'].toString(),
      name: json['name'],
      stateId: json['state_id'].toString(),
    );
  }
}
