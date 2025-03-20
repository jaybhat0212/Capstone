import SwiftUI
import HealthKit

// MARK: - Data Store (unchanged)
class ProfileStore: ObservableObject {
    private let healthStore = HKHealthStore()
    private let userDefaults = UserDefaults.standard
    
    @Published var gender: String? {
        didSet {
            userDefaults.set(gender, forKey: "gender")
        }
    }
    @Published var age: Int? {
        didSet {
            // Only set if non-nil; remove if nil so we can differentiate
            if let age = age {
                userDefaults.set(age, forKey: "age")
            } else {
                userDefaults.removeObject(forKey: "age")
            }
        }
    }
    @Published var heightFeet: Int? {
        didSet {
            if let feet = heightFeet {
                userDefaults.set(feet, forKey: "heightFeet")
            } else {
                userDefaults.removeObject(forKey: "heightFeet")
            }
        }
    }
    @Published var heightInches: Int? {
        didSet {
            if let inches = heightInches {
                userDefaults.set(inches, forKey: "heightInches")
            } else {
                userDefaults.removeObject(forKey: "heightInches")
            }
        }
    }
    @Published var weight: Int? {
        didSet {
            if let weight = weight {
                userDefaults.set(weight, forKey: "weight")
            } else {
                userDefaults.removeObject(forKey: "weight")
            }
        }
    }

    var isProfileDataComplete: Bool {
        gender != nil && age != nil && heightFeet != nil && heightInches != nil && weight != nil
    }

    // Gel Data
    @Published var gelBrand: String {
        didSet {
            userDefaults.set(gelBrand, forKey: "gelBrand")
        }
    }
    @Published var gelCalories: Int {
        didSet {
            userDefaults.set(gelCalories, forKey: "gelCalories")
        }
    }

    init() {
        // Load saved user selections from UserDefaults
        self.gender = userDefaults.string(forKey: "gender")

        if userDefaults.object(forKey: "age") != nil {
            self.age = userDefaults.integer(forKey: "age")
        } else {
            self.age = nil
        }
        if userDefaults.object(forKey: "heightFeet") != nil {
            self.heightFeet = userDefaults.integer(forKey: "heightFeet")
        } else {
            self.heightFeet = nil
        }
        if userDefaults.object(forKey: "heightInches") != nil {
            self.heightInches = userDefaults.integer(forKey: "heightInches")
        } else {
            self.heightInches = nil
        }
        if userDefaults.object(forKey: "weight") != nil {
            self.weight = userDefaults.integer(forKey: "weight")
        } else {
            self.weight = nil
        }

        // Gel brand defaults to "Gu" if none saved
        self.gelBrand = userDefaults.string(forKey: "gelBrand") ?? "Gu"

        // If userDefaults for "gelCalories" is 0 or missing, default to 75
        let storedCals = userDefaults.integer(forKey: "gelCalories")
        self.gelCalories = (storedCals == 0) ? 75 : storedCals

        fetchHealthKitData()
    }
    
    // ... HealthKit fetching methods remain the same ...
    func fetchHealthKitData() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let readTypes: Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKQuantityType.quantityType(forIdentifier: .height)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        ]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            guard success, error == nil else { return }
            self?.loadGender()
            self?.loadAge()
            self?.loadHeight()
            self?.loadWeight()
        }
    }
    
    private func loadGender() {
        do {
            let sexObj = try healthStore.biologicalSex()
            switch sexObj.biologicalSex {
            case .male:
                gender = "Male"
            case .female:
                gender = "Female"
            default:
                break
            }
        } catch { print("Error reading gender: \(error)") }
    }
    
    private func loadAge() {
        do {
            if let dob = try healthStore.dateOfBirthComponents().date {
                let now = Date()
                let comps = Calendar.current.dateComponents([.year], from: dob, to: now)
                age = comps.year
            }
        } catch { print("Error reading age: \(error)") }
    }
    
    private func loadHeight() {
        let heightType = HKQuantityType.quantityType(forIdentifier: .height)!
        let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1,
                                  sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) {
            [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample, error == nil else { return }
            
            let meters = sample.quantity.doubleValue(for: .meter())
            let totalInches = Int(round(meters * 39.3701))
            DispatchQueue.main.async {
                self?.heightFeet = totalInches / 12
                self?.heightInches = totalInches % 12
            }
        }
        healthStore.execute(query)
    }
    
    private func loadWeight() {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1,
                                  sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) {
            [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample, error == nil else { return }
            
            let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            let lb = Int(round(kg * 2.20462))
            DispatchQueue.main.async {
                self?.weight = lb
            }
        }
        healthStore.execute(query)
    }
    
    // Save overrides
    func saveProfileOverrides(gender: String, age: Int, feet: Int, inches: Int, weight: Int) {
        self.gender = gender
        self.age = age
        self.heightFeet = feet
        self.heightInches = inches
        self.weight = weight
    }
    
    func saveGelOverrides(brand: String, calories: Int) {
        gelBrand = brand
        gelCalories = calories
    }
}

// MARK: - ProfileView
struct ProfileView: View {
    @StateObject private var store = ProfileStore()
    
    @State private var showingProfileEditor = false
    @State private var showingGelEditor = false
    
    var body: some View {
        VStack(spacing: 0) {
            // -- Top Bar --
            HStack {
                Image("NRGLogo") // Replace with your asset name
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
//            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            .background(Color.black)
            
            // -- Main Content (black background) --
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    // Use spacer to help push everything toward center
                    Spacer()
                    
                    // -- User Info Section (centered) --
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .stroke(Color(red: 0.0, green: 1.0, blue: 0.8), lineWidth: 3)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.8))
                        }
                        
                        // Profile Stats
                        let genderVal = store.gender ?? "N/A"
                        let ageVal = store.age.map { "\($0)" } ?? "N/A"
                        let heightStr: String = {
                            if let f = store.heightFeet, let i = store.heightInches {
                                return "\(f)' \(i)\""
                            } else {
                                return "N/A"
                            }
                        }()
                        let weightStr = store.weight.map { "\($0) lb" } ?? "N/A"
                        
                        ProfileStatRow(label: "Gender", value: genderVal)
                        ProfileStatRow(label: "Age", value: ageVal)
                        ProfileStatRow(label: "Height", value: heightStr)
                        ProfileStatRow(label: "Weight", value: weightStr)
                        
                        // Missing data message
                        if !store.isProfileDataComplete {
                            Text("Some profile details are missing.\nTap Edit Profile to set.")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                        
                        // Edit Profile Button
                        Button {
                            showingProfileEditor.toggle()
                        } label: {
                            Text("EDIT PROFILE")
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.8))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(red: 0.0, green: 1.0, blue: 0.8), lineWidth: 1)
                                )
                        }
                    }
                    
                    // Add extra space between profile and gel card
                    Spacer(minLength: 30)
                    
                    // -- Gel Profile Card (lower on the screen) --
                    VStack(spacing: 4) {
                        Text("Gel Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Gel Brand")
                                .foregroundColor(.white)
                            Spacer()
                            Text(store.gelBrand)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 2)
                        
                        HStack {
                            Text("Calories")
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(store.gelCalories)")
                                .foregroundColor(.white)
                        }
                        
                        Button {
                            showingGelEditor.toggle()
                        } label: {
                            Text("EDIT GEL PROFILE")
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.8))
                                .padding(.top, 6)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.25, green: 0.25, blue: 0.25))
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        
        // Sheets for profile details + gel editor
        .sheet(isPresented: $showingProfileEditor) {
            ProfileEditorSheet(store: store)
        }
        .sheet(isPresented: $showingGelEditor) {
            GelEditorSheet(store: store)
        }
    }
}

// MARK: - Profile Editor (unchanged logic)
struct ProfileEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: ProfileStore
    
    @State private var tempGender: String = "Female"
    @State private var tempAge: Int = 25
    @State private var tempFeet: Int = 5
    @State private var tempInches: Int = 6
    @State private var tempWeight: Int = 150
    
    private let genderOptions = ["Female", "Male"]
    private let ageRange = Array(16...90)
    private let feetRange = Array(3...6)
    private let inchRange = Array(1...12)
    private let weightRange = Array(50...250)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Edit Profile")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                // GENDER
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gender")
                        .foregroundColor(.white)
                    Picker("Gender", selection: $tempGender) {
                        ForEach(genderOptions, id: \.self) { g in
                            Text(g).foregroundColor(.white).tag(g)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(Color(red: 0.0, green: 1.0, blue: 0.8))
                }
                
                // AGE
                VStack(alignment: .leading, spacing: 4) {
                    Text("Age")
                        .foregroundColor(.white)
                    Picker("Age", selection: $tempAge) {
                        ForEach(ageRange, id: \.self) { a in
                            Text("\(a)").foregroundColor(.white).tag(a)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }
                
                // HEIGHT
                VStack(alignment: .leading, spacing: 4) {
                    Text("Height")
                        .foregroundColor(.white)
                    HStack {
                        Picker("Feet", selection: $tempFeet) {
                            ForEach(feetRange, id: \.self) { f in
                                Text("\(f) ft").foregroundColor(.white).tag(f)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        
                        Picker("Inches", selection: $tempInches) {
                            ForEach(inchRange, id: \.self) { i in
                                Text("\(i) in").foregroundColor(.white).tag(i)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }
                }
                
                // WEIGHT
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight (lb)")
                        .foregroundColor(.white)
                    Picker("Weight", selection: $tempWeight) {
                        ForEach(weightRange, id: \.self) { w in
                            Text("\(w)").foregroundColor(.white).tag(w)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }
                
                Button("Save") {
                    store.saveProfileOverrides(
                        gender: tempGender,
                        age: tempAge,
                        feet: tempFeet,
                        inches: tempInches,
                        weight: tempWeight
                    )
                    dismiss()
                }
                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.8))
                .padding(.vertical, 8)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
            }
            .padding()
            .frame(width: 320)
            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
        .onAppear {
            if let g = store.gender, genderOptions.contains(g) {
                tempGender = g
            }
            if let a = store.age, ageRange.contains(a) {
                tempAge = a
            }
            if let f = store.heightFeet, feetRange.contains(f) {
                tempFeet = f
            }
            if let i = store.heightInches, inchRange.contains(i) {
                tempInches = i
            }
            if let w = store.weight, weightRange.contains(w) {
                tempWeight = w
            }
        }
    }
}

// MARK: - Gel Editor (unchanged logic)
struct GelEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: ProfileStore
    
    @State private var tempBrand: String = ""
    @State private var tempCalories: Double = 75.0
    
    private let brandOptions = [
        "Chargel",
        "Gu",
        "HoneyStinger",
        "Maurten",
        "NeverSecond",
        "Untapped"
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Gel Profile")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                // Gel Brand
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gel Brand")
                        .foregroundColor(.white)
                    Picker("Gel Brand", selection: $tempBrand) {
                        ForEach(brandOptions, id: \.self) { brand in
                            Text(brand)
                                .foregroundColor(.white)
                                .tag(brand)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                
                // Gel Calories
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories")
                        .foregroundColor(.white)
                    HStack {
                        Text("\(Int(tempCalories))")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    Slider(value: $tempCalories, in: 75...200, step: 5)
                        .accentColor(.white)
                }
                
                Button("Save") {
                    store.saveGelOverrides(
                        brand: tempBrand,
                        calories: Int(tempCalories)
                    )
                    dismiss()
                }
                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.8))
                .padding(.vertical, 8)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
            }
            .padding()
            .frame(width: 320)
            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
        .onAppear {
            tempBrand = store.gelBrand
            let clamped = min(max(Double(store.gelCalories), 75), 200)
            tempCalories = clamped
        }
    }
}

// MARK: - ProfileStatRow
struct ProfileStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Previews
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
        }
    }
}
