import UIKit
import CoreMedia

class ViewController: UIViewController {

    private let recorder = ScreenRecorder()
    private lazy var cmClockTimestampLabel: UILabel = {
        let subview = UILabel()
        subview.textAlignment = .center
        subview.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        subview.numberOfLines = 0
        return subview
    }()
    private lazy var toggleButton: UIButton = {
        let subview = UIButton()
        subview.setTitleColor(.blue, for: .normal)
        return subview
    }()
    private lazy var viewScreenshotsButton: UIButton = {
        let subview = UIButton()
        subview.setTitle("View Screenshots", for: .normal)
        subview.setTitleColor(.blue, for: .normal)
        subview.setTitleColor(.gray, for: .disabled)
        return subview
    }()
    private var displayLink: CADisplayLink?

    override func viewDidLoad() {
        super.viewDidLoad()
        let labelsStackView = UIStackView(arrangedSubviews: [
            cmClockTimestampLabel
        ])
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 8
        let buttonsStackView = UIStackView(arrangedSubviews: [
            toggleButton,
            viewScreenshotsButton
        ])
        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = 16
        let stackView = UIStackView(arrangedSubviews: [
            labelsStackView,
            buttonsStackView
        ])
        stackView.axis = .vertical
        stackView.spacing = 32
        view.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        displayLink?.add(to: .main, forMode: .common)

        toggleButton.addTarget(self, action: #selector(didTapToggleButton), for: .touchUpInside)
        viewScreenshotsButton.addTarget(self, action: #selector(didTapViewScreenshots), for: .touchUpInside)

        updateUIForRecordingState(recorder.isRecording)
    }

    @objc
    private func displayLinkDidFire(_ displayLink: CADisplayLink) {
        let clockTime = CMClockGetTime(CMClockGetHostTimeClock())
        assert(clockTime.timescale == 1_000_000_000)
        cmClockTimestampLabel.text = String(format: "%.3f", clockTime.seconds)
    }

    @objc
    private func didTapToggleButton() {
        toggleButton.isEnabled = false
        let completion = {
            DispatchQueue.main.async {
                self.updateUIForRecordingState(self.recorder.isRecording)
                self.toggleButton.isEnabled = true
            }
        }
        if recorder.isRecording {
            recorder.stop(completion: completion)
        } else {
            recorder.start(completion: completion)
        }
    }

    @objc
    private func didTapViewScreenshots() {
        let vc = ScreenshotsViewController(screenshotsURL: ScreenRecorder.screenshotDirectoryURL)
        vc.onClose = {
            self.dismiss(animated: true)
        }
        let nvc = UINavigationController(rootViewController: vc)
        present(nvc, animated: true)
    }

    private func updateUIForRecordingState(_ isRecording: Bool) {
        toggleButton.setTitle(isRecording ? "Stop Recording" : "Start Recording", for: .normal)
        viewScreenshotsButton.isEnabled = !isRecording
    }
}

