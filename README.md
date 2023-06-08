# AWS Transcribe Project

## Description
This project allows you to transcribe audio files using AWS Transcribe service. By pressing the "Start" button, an AWS session is created, and the application waits for the transcription to complete. The resulting text is then displayed in the text area.

## Installation
To install and configure the AWS Transcribe project, follow these steps:

1. Create permissions for AWS and generate AWS Key and AWS Secret Key.
2. Place the generated AWS Key and AWS Secret Key in the `TranscriptStream/ConfigValues.swift` file:

```swift
let AWS_KEY: String? = "<Enter Your AWS Key>"
let AWS_SECRET: String? = "<Enter Your AWS Secret>"


