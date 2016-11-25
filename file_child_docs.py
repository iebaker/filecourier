from colors import blue, red

def filename_has_prefix(filename, *prefixes):
    return any(filename.startswith(prefix) for prefix in prefixes)

def try_file_casa_internal_documents(sharefile, child_path, filename):
    if filename_has_prefix(filename, "CRWS", "CRAWS", "CMWS", "CRDCW", "ACR") or (filename_has_prefix(filename, "CVCourtReport") and filename.endswith("docx")):
        sharefile.move(filename, child_path + '/@CASA Exchange', child_path + '/CASA Internal Documents')
        return True
    return False

def try_file_casa_court_documents(sharefile, child_path, filename):
    if filename_has_prefix(filename, 'CVCourtReport') and filename.endswith('.pdf'):
        sharefile.move(filename, child_path + '/@CASA Exchange', child_path + '/CASA Court Documents')
        return True
    return False

def try_file_education_and_employment(sharefile, child_path, filename):
    if filename_has_prefix(filename, "GradeReport", "IEP", "IEPMeetingNotice", "PayStub", "ExcessAbsenceNotice", "SuspensionNotice"):
        sharefile.move(filename, child_path + '/@CASA Exchange', child_path + '/Education & Employment Documents')
        return True
    return False

def try_file_physical_and_mental_health_documents(sharefile, child_path, filename):
    if filename_has_prefix(filename, "PsychEval", "IncedentReport"):
        sharefile.move(filename, child_path + '/@CASA Exchange', child_path + '/Physical & Mental Health Documents')
        return True
    return False

def try_file_other_documents(sharefile, child_path, filename):
    if filename_has_prefix(filename, "PIC"):
        sharefile.move(filename, child_path + '/@CASA Exchange', child_path + '/Other Documents')
        return True
    return False

rules = [
    try_file_casa_internal_documents,
    try_file_casa_court_documents,
    try_file_education_and_employment,
    try_file_physical_and_mental_health_documents,
    try_file_other_documents
]

def program(sharefile, config):
    children_whitelist = config['children']

    alphabet_segments = sharefile.list('Dependent E-Files')
    alphabet_segments = {key: value for key, value in alphabet_segments.iteritems() if len(key) == 3}

    for alphabet_segment in alphabet_segments:
        children_folder_names = sharefile.list('Dependent E-Files/%s' % alphabet_segment)

        for child_folder in children_folder_names:
            if child_folder not in children_whitelist:
                continue
            child_folder_exchange_contents = sharefile.list('Dependent E-Files/%s/%s/@CASA Exchange' % (alphabet_segment, child_folder))
            for item in child_folder_exchange_contents:
                child_path = 'Dependent E-Files/%s/%s' % (alphabet_segment, child_folder)
                if not any(apply_rule(sharefile, child_path, item) for apply_rule in rules):
                    print(red('[FILE CHILD DOCS] Could not file Dependent E-Files/%s/%s/%s' % (alphabet_segment, child_folder, item)))
