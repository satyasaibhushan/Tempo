public enum ConvexAPI {
    public enum Users {
        public static let current = "users:current"
        public static let ensureCurrent = "users:ensureCurrentUser"
        public static let updateProfile = "users:updateProfile"
        public static let updatePreferences = "users:updatePreferences"
    }

    public enum AccountDeletion {
        public static let deleteCurrent = "accountDeletion:deleteCurrentAccount"
    }

    public enum TimeEntries {
        public static let listActive = "timeEntries:listActiveTimers"
        public static let listRecent = "timeEntries:listRecent"
        public static let listByDateRange = "timeEntries:listByDateRange"
        public static let start = "timeEntries:startTimer"
        public static let editActive = "timeEntries:editActiveTimer"
        public static let pause = "timeEntries:pauseTimer"
        public static let resume = "timeEntries:resumeTimer"
        public static let stop = "timeEntries:stopTimer"
        public static let discard = "timeEntries:discardTimer"
        public static let continueEntry = "timeEntries:continueEntry"
        public static let createManual = "timeEntries:createManualEntry"
        public static let edit = "timeEntries:editEntry"
        public static let delete = "timeEntries:deleteEntry"
    }

    public enum Folders {
        public static let listAll = "folders:listAllFolders"
        public static let create = "folders:createFolder"
        public static let rename = "folders:renameFolder"
        public static let move = "folders:moveFolder"
        public static let updateDefaultLabels = "folders:updateDefaultLabels"
        public static let archive = "folders:archiveFolder"
        public static let unarchive = "folders:unarchiveFolder"
        public static let delete = "folders:deleteFolder"
    }

    public enum Labels {
        public static let list = "labels:listLabels"
        public static let create = "labels:createLabel"
        public static let update = "labels:updateLabel"
        public static let delete = "labels:deleteLabel"
    }
}
