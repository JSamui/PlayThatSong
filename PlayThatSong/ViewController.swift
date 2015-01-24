//
//  ViewController.swift
//  PlayThatSong
//
//  Created by Jason on 1/24/15.
//  Copyright (c) 2015 icarus media. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController
{
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentSongLabel: UILabel!
    
    var audioSession: AVAudioSession!
    //var audioPlayer: AVAudioPlayer!
    var audioQueuePlayer: AVQueuePlayer!
    var currentSongIndex:Int!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureAudioSession()
        //self.configureAudioPlayer()
        self.configureAudioQueuePlayer()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleRequest:"), name: "WatchKitDidMakeRequest", object: nil)

    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // button IBActions
    @IBAction func playButtonPressed(sender: UIButton)
    {
        if audioQueuePlayer.rate > 0 && audioQueuePlayer.error == nil
        {
            self.audioQueuePlayer.pause()
        }
        else if currentSongIndex == nil
        {
            self.playMusic()
            self.currentSongIndex = 0
        }
        else
        {
            self.audioQueuePlayer.play()
        }
        self.updateUI()
    }
    
    @IBAction func playPreviousButtonPressed(sender: AnyObject)
    {
        if currentSongIndex > 0
        {
            self.audioQueuePlayer.pause()
            self.audioQueuePlayer.seekToTime(kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            
            let temporaryNowPlayIndex = currentSongIndex
            let temporaryPlayList = self.createSongs()
            
            self.audioQueuePlayer.removeAllItems()
            
            for var index = temporaryNowPlayIndex - 1; index < temporaryPlayList.count; index++
            {
                self.audioQueuePlayer.insertItem(temporaryPlayList[index] as AVPlayerItem, afterItem: nil)
            }
            
            self.currentSongIndex = temporaryNowPlayIndex - 1
            self.audioQueuePlayer.seekToTime(kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            self.audioQueuePlayer.play()
            self.updateUI()
        }
    }
    
    @IBAction func playNextButtonPressed(sender: AnyObject)
    {
        self.audioQueuePlayer.advanceToNextItem()
        self.currentSongIndex = self.currentSongIndex + 1
        self.updateUI()
    }
    
    // Audio Functions
    func configureAudioSession()
    {
        self.audioSession = AVAudioSession.sharedInstance()
        var categoryError:NSError?
        var activeError:NSError?
        
        self.audioSession.setCategory(AVAudioSessionCategoryPlayback, error: &categoryError)
        var success = self.audioSession.setActive(true, error: &activeError)
        println("Error: \(categoryError)")
        if !success
        {
            println("Error making audio session active \(activeError)")
        }
    }
    
    /*
    replaced with audio queue player
    func configureAudioPlayer()
    {
        var songPath = NSBundle.mainBundle().pathForResource("01 Rag Doll", ofType: "mp3")
        var songUrl = NSURL.fileURLWithPath(songPath!)
        println("\(songUrl)")
        
        var songError: NSError?
        self.audioPlayer = AVAudioPlayer(contentsOfURL: songUrl, error: &songError)
        println("Song Error: \(songError)")
        self.audioPlayer.numberOfLoops = 0
    }
    */
    
    func configureAudioQueuePlayer()
    {
        let songs = createSongs()
        self.audioQueuePlayer = AVQueuePlayer(items: songs)
        
        for var songIndex = 0; songIndex > songs.count; songIndex++
        {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "songEnded:", name: AVPlayerItemDidPlayToEndTimeNotification, object: songs[songIndex])
        }
        
    }
    
    func playMusic()
    {
        // replaced with audio queue player
        //self.audioPlayer.prepareToPlay()
        //self.audioPlayer.play()
        self.audioQueuePlayer.play()
    }
    
    func createSongs() -> [AnyObject]
    {
        let firstSongPath = NSBundle.mainBundle().pathForResource("32 Cryin'", ofType: "mp3")
        let secondSongPath = NSBundle.mainBundle().pathForResource("01 Rag Doll", ofType: "mp3")
        let thirdSongPath = NSBundle.mainBundle().pathForResource("32 I dont want to miss a thing", ofType: "mp3")
        
        let firstSongUrl = NSURL.fileURLWithPath(firstSongPath!)
        let secondSongUrl = NSURL.fileURLWithPath(secondSongPath!)
        let thirdSongUrl = NSURL.fileURLWithPath(thirdSongPath!)
        
        let firstPlayerItem = AVPlayerItem(URL:firstSongUrl)
        let secondPlayerItem = AVPlayerItem(URL: secondSongUrl)
        let thirdPlayerItem = AVPlayerItem(URL: thirdSongUrl)
        
        let songs: [AnyObject] = [firstPlayerItem,secondPlayerItem,thirdPlayerItem]
        return songs
    }
    
    // audio notification
    func songEnded(notification:NSNotification)
    {
        self.currentSongIndex = self.currentSongIndex + 1
        self.updateUI()
    }
    
    // ui update helpers
    func updateUI ()
    {
        self.currentSongLabel.text = currentSongName()
        
        if audioQueuePlayer.rate > 0 && audioQueuePlayer.error == nil
        {
            self.playButton.setTitle("Pause", forState: UIControlState.Normal)
        }
        else
        {
            self.playButton.setTitle("Play", forState: UIControlState.Normal)
        }
    }
    
    func currentSongName () -> String
    {
        var currentSong: String
        if currentSongIndex == 0
        {
            currentSong = "Crying"
        }
        else if currentSongIndex == 1
        {
            currentSong = "Rag Doll"
        }
        else if currentSongIndex == 2
        {
            currentSong = "I dont want to miss a thing"
        }
        else
        {
            currentSong = "No Song Playing"
            println("Something went wrong")
        }
        return currentSong
    }
    
    // watch kit notification
    
    func handleRequest(notification : NSNotification)
    {
        let watchKitInfo = notification.object! as WatchKitInfo
        if watchKitInfo.playerRequest != nil
        {
            let requestedAction: String = watchKitInfo.playerRequest!
            //self.playMusic()
            switch requestedAction
            {
                case "Play":
                    self.playMusic()
                case "Next":
                    self.playNextButtonPressed(self)
                case "Previous":
                    self.playPreviousButtonPressed(self)
                default:
                println("default Value Printed, somethign went wrong")
            }
            let currentSongDictionary = ["CurrentSong" : currentSongName()]
            watchKitInfo.replyBlock(currentSongDictionary)
            self.updateUI()
        }
    }
}