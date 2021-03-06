import 'dart:async';
import 'dart:io';

import 'package:milestone_educom/src/atp/default.dart';
import 'package:milestone_educom/src/helpers/fonts.dart';
import 'package:milestone_educom/src/helpers/validation.dart';
import 'package:milestone_educom/src/helpers/vars.dart';
import 'package:milestone_educom/src/providers/theme.dart';
import 'package:milestone_educom/src/providers/user.dart';
import 'package:milestone_educom/src/resources/api.dart';
import 'package:milestone_educom/src/routes/list.dart' as routeList;
import 'package:milestone_educom/src/screens/users/editable.dart';
import 'package:milestone_educom/src/screens/users/tappable.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xs_progress_hud/xs_progress_hud.dart';

class EditProfilePage extends StatefulWidget {
  final bool shouldPop;

  EditProfilePage({Key key, @required this.shouldPop}) : super(key: key);

  @override
  _EditProfilePage createState() => _EditProfilePage();
}

class _EditProfilePage extends State<EditProfilePage> {
  ApiProvider _apiProvider = ApiProvider();
  bool loading = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController schoolController = TextEditingController();
  TextEditingController educationController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(microseconds: 1), getInitialData);
  }

  getInitialData() async {
    final UserBloc userBloc = Provider.of<UserBloc>(context);

    nameController.text = userBloc.user.name;
    emailController.text = userBloc.user.email;
    dobController.text = userBloc.user.dob;
    genderController.text = userBloc.user.gender;
    schoolController.text = userBloc.user.school;
    educationController.text = userBloc.user.education;
  }

  Widget getLeadingIcon() {
    if (widget.shouldPop == true) {
      return IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    }

    return Icon(Icons.person);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeBloc themeBloc = Provider.of<ThemeBloc>(context);
    final UserBloc userBloc = Provider.of<UserBloc>(context);

    final DefaultTheme theme = themeBloc.theme;

    return Scaffold(
      backgroundColor: theme.editProfile.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.editProfile.backgroundColor,
        title: Text(
          "Edit Profile".toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14.0,
            color: Colors.white,
            fontFamily: Fonts.titilliumWebSemiBold,
          ),
        ),
        leading: getLeadingIcon(),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              onSubmit(userBloc);
            },
            child: Text(
              "SUBMIT",
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12.0,
                color: Colors.white,
                fontFamily: Fonts.titilliumWebSemiBold,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(height: 20.0),
              if (widget.shouldPop == true) photoUpload(userBloc),
              EditableFormField(
                cursorColor: theme.editProfile.cursorColor,
                controller: nameController,
                labelText: "Full Name",
                errorText: getErrorText(userBloc.error, 'name'),
                onChanged: (name) {
                  userBloc.onChangeData("name", name, userBloc.user);
                },
              ),
              if (widget.shouldPop == false)
                EditableFormField(
                  cursorColor: theme.editProfile.cursorColor,
                  controller: emailController,
                  labelText: "Email Address",
                  errorText: getErrorText(userBloc.error, 'email'),
                  onChanged: (email) {
                    userBloc.onChangeData("email", email, userBloc.user);
                  },
                ),
              GestureDetector(
                onTap: () async {
                  final String userDob = userBloc.user.dob;
                  List dateList = userDob.split("-");
                  DateTime intialDob = DateTime(
                    int.parse(dateList[2]),
                    int.parse(dateList[1]),
                    int.parse(dateList[0]),
                  );

                  final DateTime dob = await showDatePicker(
                    initialDatePickerMode: DatePickerMode.day,
                    context: context,
                    initialDate: intialDob,
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2100),
                  );

                  if (dob != null) {
                    String formattedDob = DateFormat('dd-MM-yyyy').format(dob);
                    setState(() => dobController.text = formattedDob);
                    userBloc.onChangeData("dob", formattedDob, userBloc.user);
                  }
                },
                child: TappableFormField(
                  controller: dobController,
                  labelText: "Date of Birth",
                  errorText: getErrorText(userBloc.error, "dob"),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, routeList.gender).then((gender) {
                    if (gender != null) {
                      setState(() {
                        genderController.text = gender;
                      });
                    }
                  }).catchError((onError) {
                    print(onError);
                  });
                },
                child: TappableFormField(
                  controller: genderController,
                  labelText: "Gender",
                  errorText: getErrorText(userBloc.error, "gender"),
                ),
              ),
              EditableFormField(
                cursorColor: theme.editProfile.cursorColor,
                controller: schoolController,
                labelText: "School",
                errorText: getErrorText(userBloc.error, 'school'),
                onChanged: (school) {
                  userBloc.onChangeData("school", school, userBloc.user);
                },
              ),
              EditableFormField(
                cursorColor: theme.editProfile.cursorColor,
                controller: educationController,
                labelText: "Education",
                errorText: getErrorText(userBloc.error, 'education'),
                onChanged: (education) {
                  userBloc.onChangeData("education", education, userBloc.user);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  photoUpload(userBloc) {
    return GestureDetector(
      onTap: () {
        uploadImage(userBloc);
      },
      child: Container(
        height: 120.0,
        width: 120.0,
        margin: EdgeInsets.only(bottom: 20.0),
        child: ClipOval(
            child: CachedNetworkImage(
          imageUrl: "$baseUrl/storage/${userBloc.user.avatar}",
          placeholder: (context, url) {
            return CircularProgressIndicator();
          },
          errorWidget: (context, url, error) => Icon(Icons.error),
          width: 120.0,
          height: 120.0,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        )),
      ),
    );
  }

  onSubmit(UserBloc userBloc) async {
    XsProgressHud.show(context);

    if (widget.shouldPop == true) {
      await userBloc.updateProfile(userBloc.user);
    } else {
      await userBloc.createProfile(userBloc.user);
    }

    XsProgressHud.hide();

    if (userBloc.loaded == true && userBloc.error == null) {
      if (widget.shouldPop == true) {
        Navigator.of(context).pop();
      } else {
        Navigator.pushReplacementNamed(context, routeList.home);
      }
    }
  }

  void uploadImage(userBloc) async {
    final File image = await ImagePicker.pickImage(source: ImageSource.gallery);
    final File file = await ImageCropper.cropImage(
      sourcePath: image.path,
      ratioX: 1.0,
      ratioY: 1.0,
      maxWidth: 512,
      maxHeight: 512,
    );

    setState(() {
      loading = true;
    });

    FormData formdata = FormData.from({
      "image": UploadFileInfo(file, file.path),
    });

    try {
      final response = await _apiProvider.uploadAvatar(formdata);
      final results = response.data;

      await userBloc.setAuthUser(results['user']);

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }
}
