import '../network/api_client.dart';

class FinanceApiService {
  static Future<Map<String, dynamic>> getStudentFinance(
      String studentId) async {
    final response =
        await ApiClient.instance.get('/finance/student/$studentId');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> recordPayment(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/payments', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getStats({String? year}) async {
    final response = await ApiClient.instance.get(
      '/finance/stats',
      params: {if (year != null) 'year': year},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getFees({String? year}) async {
    final response = await ApiClient.instance.get(
      '/finance/fees',
      params: {if (year != null) 'year': year},
    );
    return response.data as List<dynamic>;
  }

  static Future<List<dynamic>> listPayments({String? year}) async {
    final response = await ApiClient.instance.get(
      '/finance/payments',
      params: {if (year != null) 'year': year},
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createFee(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post('/finance/fees', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> cashCurrent() async {
    final response = await ApiClient.instance.get('/finance/cash/current');
    if (response.data == null) return null;
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<List<dynamic>> cashSessions({int limit = 20}) async {
    final response = await ApiClient.instance.get(
      '/finance/cash/sessions',
      params: {'limit': limit},
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> cashOpen(Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/cash/open', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> cashClose(Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/cash/close', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> listExpenses({String? year}) async {
    final response = await ApiClient.instance.get(
      '/finance/expenses',
      params: {if (year != null) 'year': year},
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createExpense(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/expenses', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> listSuppliers() async {
    final response = await ApiClient.instance.get('/finance/suppliers');
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createSupplier(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/suppliers', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> listPayroll({String? year}) async {
    final response = await ApiClient.instance.get(
      '/finance/payroll',
      params: {if (year != null) 'year': year},
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createPayroll(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/payroll', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> payrollStatus(
      String id, String status) async {
    final response = await ApiClient.instance.patch(
      '/finance/payroll/$id/status',
      data: {'status': status},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> listBudgets({String? year}) async {
    final response = await ApiClient.instance.get(
      '/finance/budgets',
      params: {if (year != null) 'year': year},
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createBudget(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/budgets', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> budgetVsActual(String id) async {
    final response =
        await ApiClient.instance.get('/finance/budgets/$id/vs-actual');
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> listBankAccounts() async {
    final response = await ApiClient.instance.get('/finance/bank/accounts');
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createBankAccount(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/bank/accounts', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> listBankTransactions(String accountId) async {
    final response = await ApiClient.instance
        .get('/finance/bank/accounts/$accountId/transactions');
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createBankTransaction(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/bank/transactions', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> reconcileBank(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/bank/reconcile', data: data);
    return response.data as Map<String, dynamic>;
  }
}
