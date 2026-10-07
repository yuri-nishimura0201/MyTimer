import AVFoundation
import UIKit

final class SoundPlayer {
    private var player: AVAudioPlayer?

    func playCompletionSound() {
        guard let data = NSDataAsset(name: "hato")?.data else { return }

        do {
            player = try AVAudioPlayer(data: data)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("終了音を再生できませんでした: \(error.localizedDescription)")
        }
    }
}
