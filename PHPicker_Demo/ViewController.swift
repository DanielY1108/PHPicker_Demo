//
//  ViewController.swift
//  PHPicker_Demo
//
//  Created by JINSEOK on 2023/04/05.
//

import UIKit
import PhotosUI
import SnapKit

class ViewController: UIViewController {
    
    // Identifier와 PHPickerResult로 만든 Dictionary
    private var selections = [String : PHPickerResult]()
    // 선택한 사진의 Identifier들을 담아줄 것입니다.
    private var selectedAssetIdentifiers = [String]()
    // 순서있는 작업을 위해서 시퀀스를 만들어 줘야합니다.
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    
    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.spacing = 10
        stack.axis = .vertical
        stack.distribution = .equalCentering
        return stack
    }()
    
    lazy var button: UIButton = {
        let button = UIButton(frame: CGRect(x: (view.frame.width/2)-50, y: 720, width: 100, height: 60))
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 20
        button.setTitle("PHPicker", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(button)
        view.addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(self.view.safeAreaLayoutGuide).offset(20)
        }
        
        button.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
    }
    
    @objc func buttonHandler(_ sender: UIButton) {
        presentPicker()
    }
    
    private func addImage(_ image: UIImage) {
        let imageView = UIImageView()
        imageView.image = image
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(200)
        }
        
        stackView.addArrangedSubview(imageView)
    }
    
    
    private func presentPicker() {
        // 이미지의 Identifier를 사용하기 위해서는 초기화를 shared로 해줘야 합니다.
        var config = PHPickerConfiguration(photoLibrary: .shared())
        // 라이브러리에서 보여줄 Assets을 필터를 한다. (기본값: 이미지, 비디오, 라이브포토)
        config.filter = PHPickerFilter.any(of: [.images])
        // 다중 선택 갯수 설정 (0 = 무제한)
        config.selectionLimit = 3
        // 선택 동작을 나타냄 (default: 기본 틱 모양, ordered: 선택한 순서대로 숫자로 표현, people: 뭔지 모르겠게요)
        config.selection = .ordered
        // 잘은 모르겠지만, current로 설정하면 트랜스 코딩을 방지한다고 하네요!?
        config.preferredAssetRepresentationMode = .current
        // 이 동작이 있어야 PHPicker를 실행 시, 선택했던 이미지를 기억해 표시할 수 있다. (델리게이트 코드 참고)
        config.preselectedAssetIdentifiers = selectedAssetIdentifiers
        
        // 만든 Configuration를 사용해 PHPicker 컨트롤러 객체 생성
        let imagePicker = PHPickerViewController(configuration: config)
        imagePicker.delegate = self
        
        self.present(imagePicker, animated: true)
    }
    
    
    private func displayImage() {
        
        // 처음 스택뷰의 서브뷰들을 모두 제거함
        self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for identifier in selectedAssetIdentifiers {
            
            guard let result = selections[identifier] else { return }
            
            let itemProvider = result.itemProvider
            // 만약 itemProvider에서 UIImage로 로드가 가능하다면?
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                print("처음 \(identifier)")
                let a = itemProvider.registeredTypeIdentifiers
                print(a)
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    
                    print("중간 \(identifier)")
                    
                    guard let self = self,
                          let image = image as? UIImage else { return }
                    
                    DispatchQueue.main.async {
                        self.addImage(image)
                        print("마지막 \(identifier)")
                    }
                }
            }
        }
    }
}



extension ViewController : PHPickerViewControllerDelegate {
    // picker가 종료되면 동작 함
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        // picker가 선택이 완료되면 화면 내리기
        picker.dismiss(animated: true)
        
        // 기존에 선택했던 PHPickerResult를 넣어 줍니다. (처음은 당연히 [:] 이므로 nil)
        let existingSelection = self.selections
        // Picker의 동작이 완료 된 후 result를 담아줄 변수를 생성
        var newSelection = [String: PHPickerResult]()
        
        for result in results {
            let identifier = result.assetIdentifier!
            // 처음에는 무조건 newSelection에 result 값을 담아주고,
            // 그 다음부터는 selection값이 존재하면 재사용, 존재하지 않으면 result 사용해서 담아줍니다.
            newSelection[identifier] = existingSelection[identifier] ?? result
        }
        
        // 새로 만들어진 newSelection을 사용
        selections = newSelection
        
        // Picker에 선택한 이미지의 Identifier를 저장해준다. (keyPath를 통해 접근하여 map으로 변환해 줌)
        // 위의 PHPickerConfiguration에서 사용하기 위함
        selectedAssetIdentifiers = results.map(\.assetIdentifier!)
        // 시퀀스를 만들기 위해 makeIterator를 사용
        selectedAssetIdentifierIterator = selectedAssetIdentifiers.makeIterator()
        
        // 만약 selection이 하나라도 있다면 displayImage 실행
        if !selections.isEmpty {
            displayImage()
        }
    }
}
