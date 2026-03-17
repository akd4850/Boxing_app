# Boxing App 개발 환경 설정 가이드

## 개발 환경 요약

| 항목 | 상태 |
|---|---|
| OS | Windows 11 Pro |
| IDE | Visual Studio Code ✅ |
| Git | v2.52.0 ✅ |
| VS Code Flutter 확장 | v3.130.0 ✅ |
| Flutter SDK | v3.41.4 ✅ (C:\flutter) |
| Android Studio | ✅ 설치 완료 |
| Android SDK | v36.1.0 ✅ |
| Android cmdline-tools | ✅ 설치 완료 |
| Android 라이선스 | ✅ 동의 완료 |

---

## Step 1. Flutter SDK 설치

1. 아래 링크에서 Flutter SDK 다운로드
   - https://docs.flutter.dev/get-started/install/windows/mobile
2. `C:\flutter` 에 압축 해제
3. 환경변수 PATH에 Flutter 경로 추가
   - `시작` → `환경 변수 편집` 검색 → `시스템 환경 변수`
   - `Path` 선택 → `편집` → `새로 만들기`
   - `C:\flutter\bin` 입력 후 확인
4. 터미널 재시작 후 확인:
   ```bash
   flutter --version
   ```

---

## Step 2. Android Studio 설치

Android SDK와 에뮬레이터를 위해 필요합니다. (코딩은 VS Code에서 합니다)

1. 아래 링크에서 Android Studio 다운로드 & 설치
   - https://developer.android.com/studio
2. 설치 시 아래 항목 체크:
   - Android SDK
   - Android SDK Command-line Tools
   - Android Emulator
3. 설치 완료 후 Android Studio 실행
4. `More Actions` → `SDK Manager` 진입
   - SDK Platforms 탭: 최신 Android API 선택
   - SDK Tools 탭: 아래 항목 체크 확인
     - Android SDK Build-Tools
     - Android SDK Command-line Tools
     - Android Emulator
     - Android SDK Platform-Tools

---

## Step 3. Android 라이선스 동의

```bash
flutter doctor --android-licenses
```

모든 항목에 `y` 입력하여 동의.

---

## Step 4. Android 에뮬레이터 설정

1. Android Studio → `More Actions` → `Virtual Device Manager`
2. `Create Device` 클릭
3. 기기 선택 (권장: Pixel 8)
4. 시스템 이미지 선택 → 최신 버전 다운로드
5. 에뮬레이터 이름 설정 후 `Finish`
6. 생성된 에뮬레이터 ▶ 버튼으로 실행 확인

---

## Step 5. VS Code 확장 (설치 완료)

아래 확장이 설치되어 있습니다:
- **Flutter** v3.130.0
- **Dart** v3.130.1

---

## Step 6. 설치 확인

```bash
flutter doctor
```

모든 항목에 `[√]` 가 뜨면 설정 완료.

---

## Step 7. 프로젝트 생성 (설정 완료 후)

```bash
flutter create boxing_app
cd boxing_app
flutter run
```

---

## 참고사항

- **Visual Studio C++ 빌드 도구** 경고는 Windows 데스크톱 앱 전용이므로 모바일 개발에는 무관
- iOS 빌드 및 시뮬레이터는 **Mac + Xcode** 환경에서만 가능
- 현재 Windows 환경에서는 Android 개발에 집중
- iOS 배포가 필요한 시점에 Mac 환경 준비 필요
