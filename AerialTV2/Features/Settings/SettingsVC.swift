//
//  SettingsVC.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 27.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import UIKit


class SettingsVC: UIViewController {

    private var settings = Settings(sections: [
        Settings.Section(title: "SettingsDate".localized(), rows: [
            Settings.Section.Row(title: "SettingsDateShowDate".localized(), isChecked: AerialSettings.shared.showDate) { row in
                row.isChecked = !row.isChecked
                AerialSettings.shared.showDate = row.isChecked
            },
            Settings.Section.Row(title: "SettingsDateShowTime".localized(), isChecked: AerialSettings.shared.showTime) { row in
                row.isChecked = !row.isChecked
                AerialSettings.shared.showTime = row.isChecked
            }
        ])
    ])

    @IBOutlet var tableView: UITableView!

    @IBOutlet var labelAppName: UILabel!
    @IBOutlet var labelAppVersion: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        labelAppName.text = Bundle.main.infoDictionary?["CFBundleName"] as? String
        labelAppVersion.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

}


extension SettingsVC: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return settings.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = settings.sections[safe: section] else { return 0 }
        return section.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)

        guard let section = settings.sections[safe: indexPath.section] else { return cell }
        guard let row = section.rows[safe: indexPath.row] else { return cell }

        cell.textLabel?.text = row.title
        cell.accessoryType = row.isChecked ? .checkmark : .none

        return cell
    }

}


extension SettingsVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = settings.sections[safe: section] else { return nil }
        return section.title
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = settings.sections[safe: indexPath.section] else { return }
        guard let row = section.rows[safe: indexPath.row] else { return }

        row.toggle(row)
        tableView.reloadData()
    }

}


extension SettingsVC {

    class Settings {

        public var sections: [Section]

        public init(sections: [Section]) {
            self.sections = sections
        }

    }

}


extension SettingsVC.Settings {

    class Section {

        public var title: String
        public var rows: [Row]

        public init(title: String, rows: [Row]) {
            self.title = title
            self.rows = rows
        }

    }

}


extension SettingsVC.Settings.Section {

    class Row {

        public var title: String
        public var isChecked: Bool
        public var toggle: (Row) -> Void

        public init(title: String, isChecked: Bool, toggle: @escaping (Row) -> Void) {
            self.title = title
            self.isChecked = isChecked
            self.toggle = toggle
        }

    }

}
