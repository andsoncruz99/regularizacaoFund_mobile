String formDataToQueryString(formData) {
  String queryString = '';

  formData.forEach((chave, valor) {
    if (queryString.isNotEmpty) {
      queryString += '&'; // Adiciona '&' entre os pares chave-valor
    }
    if (valor != null)
      queryString += Uri.encodeComponent(chave) +
          '=' +
          Uri.encodeComponent(valor.toString());
  });

  return queryString;
}
