//
//  ViewController.swift
//  SpeechKit
//
//  Created by HUAMEi on 2018/6/15.
//  Copyright © 2018年 HUAMEi. All rights reserved.
//

import UIKit
import Speech
import MediaPlayer
import AVKit

class ViewController: UIViewController,SFSpeechRecognizerDelegate,AVSpeechSynthesizerDelegate {
    
    
    @IBOutlet weak var text: UITextField!
    
    @IBOutlet weak var shibie: UIButton!
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh-CN"))
    //处理语音识别请求。
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    //告诉你语音识别对象的结果
    private var recognitionTask: SFSpeechRecognitionTask?
    //语音引擎，负责提供语音输入
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shibie.isEnabled = false
        speechRecognizer?.delegate = self
        //检测授权状态，再根绝状态，判断识别按钮是否可用
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isbuttonEnable = false
            switch authStatus {
            case .authorized:
                isbuttonEnable = true
            case .denied:
                isbuttonEnable = false
                print("用户拒绝语音识别")
            case .restricted:
                isbuttonEnable = false
                print("此设备不支持语音识别")
            case .notDetermined:
                print("语音识别未批准")
            }
            
            OperationQueue.main.addOperation {
                self.shibie.isEnabled = isbuttonEnable
            }
        }
        
    }
    
    @objc func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch  {
            print("因为一个错误语音任务未能进行")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
       
        
        guard let recognitionRequest = recognitionRequest else {
            
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
            
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.text.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.shibie.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch  {
            print("audioEngine couldn't start because of an error.")
        }
        text.text = "Say something, I'm listening"
    }
    //触发语音识别
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            shibie.isEnabled = true
        }else{
            shibie.isEnabled = false
        }
    }
    
    @IBAction func yuyinshibie(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            shibie.isEnabled = false
            shibie.setTitle("开始识别", for: .normal)
        }else{
            startRecording()
            shibie.setTitle("停止识别", for: .normal)
        }
        
    }
    var message = "测试音频"
    let synth = AVSpeechSynthesizer() //TTS对象
    let audioSession = AVAudioSession.sharedInstance() //语音引擎
    @IBAction func speak(_ sender: Any) {
        synth.delegate = self
        if !message.isEmpty {
            do {
                // 设置语音环境，保证能朗读出声音（特别是刚做过语音识别，这句话必加，不然没声音）
                try audioSession.setCategory(AVAudioSessionCategoryAmbient)
            }catch let error as NSError{
                print(error.code)
            }
            //需要转的文本
            let utterance = AVSpeechUtterance.init(string: message)
            //设置语言，这里是中文
            utterance.voice = AVSpeechSynthesisVoice.init(language: "zh_CN")
            //设置声音大小
            utterance.volume = 1
            //设置音频
            utterance.pitchMultiplier = 1.1
            //开始朗读
            synth.speak(utterance)
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

