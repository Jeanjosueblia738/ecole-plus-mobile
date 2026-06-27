class SmsTemplateService {
  static String absenceNotification({
    required String studentName,
    required String subject,
    required String date,
    required String duration,
  }) {
    return 'ECOLE+ | Information absence\n'
        'Élève : $studentName\n'
        'Matière : $subject\n'
        'Date : $date\n'
        'Durée : $duration\n'
        'Merci de contacter l’administration.';
  }
}
