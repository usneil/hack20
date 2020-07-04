import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter95/flutter95.dart';
import 'package:image_picker/image_picker.dart';
import '../shared/loader.dart';

class NewPolaroidScreen extends StatefulWidget {
  @override
  _NewPolaroidScreenState createState() => _NewPolaroidScreenState();
}

class _NewPolaroidScreenState extends State<NewPolaroidScreen> {
  final TextEditingController titleController =
      TextEditingController(text: "A fun moment!");

  File _image;
  String _uploadedImageURL;

  bool loadingPosting = false;

  Future chooseFile() async {
    await ImagePicker.pickImage(source: ImageSource.camera).then((image) {
      setState(() {
        if (image != null) {
          _image = image;
          _uploadedImageURL = null;
        }
      });
    });

    final storageReference =
        FirebaseStorage.instance.ref().child('images/${DateTime.now()}.png');
    final uploadTask = storageReference.putFile(_image);

    await uploadTask.onComplete;

    storageReference.getDownloadURL().then((fileURL) {
      setState(() {
        _uploadedImageURL = fileURL;
      });
    });
  }

  Future createPost() async {
    setState(() => loadingPosting = true);

    await CloudFunctions.instance
        .getHttpsCallable(
      functionName: 'createPost',
    )
        .call({"title": titleController.text, "imageURL": _uploadedImageURL});

    setState(() => loadingPosting = false);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isUploaded = _uploadedImageURL != null;
    final isSelected = _image != null;
    final isUploading = isSelected && !isUploaded;

    return Scaffold95(
      title: 'New Polaroid',
      body: Padding(
        padding: const EdgeInsets.all(3),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Caption:", style: Flutter95.textStyle),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: TextField95(
                key: const Key("Caption Input"),
                controller: titleController,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                !isUploading
                    ? Expanded(
                        child: Button95(
                          onTap: chooseFile,
                          child: Center(
                              child: isUploaded
                                  ? const Text('Take Another Image')
                                  : const Text("Take Image")),
                        ),
                      )
                    : const SizedBox(),
                isUploaded
                    ? Expanded(
                        child: Button95(
                          onTap: createPost,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              loadingPosting
                                  ? const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Loader(size: 18),
                                    )
                                  : const SizedBox(),
                              const Text('Post'),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox()
              ],
            ),
            isUploaded
                ? Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Image:',
                          style: TextStyle(
                            color: Flutter95.headerLight,
                            fontSize: 20,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Image.asset(
                        _image.path,
                        height: 400,
                      ),
                    ],
                  )
                : const SizedBox(),
            isUploading
                ? const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Loader(size: 60),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
