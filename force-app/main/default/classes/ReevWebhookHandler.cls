@RestResource(urlMapping='/reevWebhook/*')
global with sharing class ReevWebhookHandler {
    
    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Corrigindo a conversão de Blob para String
        Blob requestBodyBlob = req.requestBody;
        String requestBody = requestBodyBlob != null ? requestBodyBlob.toString() : '';
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

        // Processar os dados recebidos e salvar no Salesforce
        String firstName = (String) data.get('Nome');
        String lastName = (String) data.get('Sobrenome');
        String email = (String) data.get('E-mail');
        String company = (String) data.get('Empresa');
        String position = (String) data.get('Cargo');
        String telephone = (String) data.get('Telefone');
        String cellphone = (String) data.get('Celular');
        String address = (String) data.get('Endereco');
        String linkedin = (String) data.get('Linkedin');
        String url = (String) data.get('URL');

        // Verificação para garantir que o email não está vazio
        if (email == null || email == '') {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('Missing email field');
            return;
        }

        // Consultar lead existente pelo email
        List<Lead> leads = [SELECT Id, Email FROM Lead WHERE Email = :email LIMIT 1];
        Lead lead;
        if (leads.isEmpty()) {
            lead = new Lead();
            lead.Email = email; // Defina o campo email
        } else {
            lead = leads[0];
        }

        // Atualizar ou criar lead
        lead.FirstName = firstName;
        lead.LastName = lastName;
        lead.Company = company;
        lead.Title = position;
        lead.Phone = telephone;
        lead.MobilePhone = cellphone;
        lead.Street = address;
        lead.LinkedIn_Profile__c = linkedin;
        lead.Website = url;

        // Verificar se o lead tem o campo Email preenchido antes do upsert
        if (lead.Email == null || lead.Email == '') {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('Email is required for upsert');
            return;
        }

        upsert lead Email; // Use o campo Email como chave externa para upsert

        res.statusCode = 200;
        res.responseBody = Blob.valueOf('Success');
    }
}



/* @RestResource(urlMapping='/reevWebhook/*')
global with sharing class ReevWebhookHandler {
    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Corrigindo a conversão de Blob para String
        Blob requestBodyBlob = req.requestBody;
        String requestBody = requestBodyBlob != null ? requestBodyBlob.toString() : '';
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

        // Acessar o token armazenado em metadados personalizados
        Webhook_Security_Settings__mdt settings = [SELECT Token__c FROM Webhook_Security_Settings__mdt WHERE DeveloperName = 'Reev_Webhook_Token' LIMIT 1];
        String expectedToken = settings.Token__c;
        String receivedToken = req.headers.get('Authorization');
        if (expectedToken != receivedToken) {
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('Unauthorized'); // Converting String to Blob
            return;
        }

        // Processar os dados recebidos e salvar no Salesforce
        String firstName = (String) data.get('Nome');
        String lastName = (String) data.get('Sobrenome');
        String email = (String) data.get('E-mail');
        String company = (String) data.get('Empresa');
        String position = (String) data.get('Cargo');
        String telephone = (String) data.get('Telefone');
        String cellphone = (String) data.get('Celular');
        String address = (String) data.get('Endereco');
        String linkedin = (String) data.get('Linkedin');
        String url = (String) data.get('URL');

        // Consultar lead existente pelo email
        List<Lead> leads = [SELECT Id FROM Lead WHERE Email = :email LIMIT 1];
        Lead lead;
        if (leads.isEmpty()) {
            lead = new Lead();
            lead.Email = email; // Defina o campo email
        } else {
            lead = leads[0];
        }

        // Atualizar ou criar lead
        lead.FirstName = firstName;
        lead.LastName = lastName;
        lead.Company = company;
        lead.Title = position;
        lead.Phone = telephone;
        lead.MobilePhone = cellphone;
        lead.Street = address; // Considerando que o campo `address` contém apenas a rua
        lead.LinkedIn_Profile__c = linkedin;
        lead.Website = url;

        upsert lead Email; // Use o campo Email como chave externa para upsert

        res.statusCode = 200;
        res.responseBody = Blob.valueOf('Success'); // Converting String to Blob
    }
} */


/* @RestResource(urlMapping='/reevWebhook/*')
global with sharing class ReevWebhookHandler {
    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Corrigindo a conversão de Blob para String
        Blob requestBodyBlob = req.requestBody;
        String requestBody = requestBodyBlob != null ? requestBodyBlob.toString() : '';
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

        // Acessar o token armazenado em metadados personalizados
        Webhook_Security_Settings__mdt settings = [SELECT Token__c FROM Webhook_Security_Settings__mdt WHERE DeveloperName = 'Reev_Webhook_Token' LIMIT 1];
        String expectedToken = settings.Token__c;
        String receivedToken = req.headers.get('Authorization');
        if (expectedToken != receivedToken) {
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('Unauthorized'); // Converting String to Blob

            return;
        }

        // Processar os dados recebidos e salvar no Salesforce
        String firstName = (String) data.get('first_name');
        String lastName = (String) data.get('last_name');
        String email = (String) data.get('email');
        String linkedin = (String) data.get('linkedin');
        String url = (String) data.get('url');
        String company = (String) data.get('business');
        String telephone = (String) data.get('telephone');
        String address = (String) data.get('address'); // Presume-se que isso contenha apenas a rua, ajuste conforme necessário
        String position = (String) data.get('position');
        String cellphone = (String) data.get('cellphone');

        // Custom fields
        List<Map<String, Object>> customFields = (List<Map<String, Object>>) data.get('custom_fields');
        Map<String, String> customFieldsMap = new Map<String, String>();
        for (Map<String, Object> field : customFields) {
            customFieldsMap.put((String) field.get('field'), (String) field.get('value'));
        }

        // Processar campos customizados
        String variavel1 = customFieldsMap.get('Variável 1');
        String variavel2 = customFieldsMap.get('Variável 2');
        String variavel3 = customFieldsMap.get('Variável 3');
        String senioridade = customFieldsMap.get('Senioridade');
        String quantidadeFuncionarios = customFieldsMap.get('Quantidade de funcionários');
        String reclameAquiResumo = customFieldsMap.get('Reclame Aqui (resumo)');
        String reclamacoesPorCategoria = customFieldsMap.get('Reclamações por categoria');
        String reclamacoesPorProblema = customFieldsMap.get('Reclamações por problema');
        String reclamacoesPorProduto = customFieldsMap.get('Reclamações por produto');
        String origem = customFieldsMap.get('Origem');
        String faixaDeFaturamento = customFieldsMap.get('Faixa de faturamento');
        String tipoDeProjeto = customFieldsMap.get('Tipo de projeto');
        String ticketMedio = customFieldsMap.get('Ticket médio');
        String tecnologiaAtual = customFieldsMap.get('Tecnologia atual(s)');
        String processoDeVendas = customFieldsMap.get('Processo de vendas');
        String nuvensUtilizadas = customFieldsMap.get('Nuvens utilizadas');
        String ticketMedioDasVendasDaEmpresa = customFieldsMap.get('Ticket médio das vendas da empresa');
        String escopoDoProjeto = customFieldsMap.get('Escopo do Projeto');
        String tipoDeReceita = customFieldsMap.get('Tipo de receita');
        String utilizaChatbot = customFieldsMap.get('Utiliza chatbot?');
        String tamanhoDoTimeDeVendasAtendimento = customFieldsMap.get('Tamanho do time de vendas/atendimento');

        // Consultar lead existente pelo email
        List<Lead> leads = [SELECT Id FROM Lead WHERE Email = :email LIMIT 1];
        Lead lead;
        if (leads.isEmpty()) {
            lead = new Lead();
            lead.Email = email; // Defina o campo email
        } else {
            lead = leads[0];
        }

        // Atualizar ou criar lead - SF = Reev
        lead.FirstName = firstName;
        lead.LastName = lastName;
        lead.Company = company;
        lead.Title = position;
        lead.Phone = telephone;
        lead.MobilePhone = cellphone;
        // Atualizar os campos de endereço individualmente
        lead.Street = address; // Considerando que o campo `address` contém apenas a rua
        // Para outros campos de endereço (City, State, PostalCode), ajuste conforme necessário
        lead.Website = url;
        lead.LinkedIn_Profile__c = linkedin;
        lead.Variable1__c = variavel1;
        lead.Variable2__c = variavel2;
        lead.Variable3__c = variavel3;
        lead.Senioridade__c = senioridade;
        // Corrigindo o campo Quantidade_de_Funcionarios__c
        if (quantidadeFuncionarios != null) {
            lead.Quantidade_de_Funcionarios__c = Integer.valueOf(quantidadeFuncionarios);
        }
        lead.Reclame_Aqui_Resumo__c = reclameAquiResumo;
        lead.Reclamacoes_por_Categoria__c = reclamacoesPorCategoria;
        lead.Reclamacoes_por_Problema__c = reclamacoesPorProblema;
        lead.Reclamacoes_por_Produto__c = reclamacoesPorProduto;
        lead.LeadSource = origem; //lead.Origem__c = origem;
        lead.Faixa_de_Faturamento__c = faixaDeFaturamento;
        lead.Tipo_de_Projeto__c = tipoDeProjeto;
        // Corrigindo a atribuição de ticketMedio
        if (ticketMedio != null) {
            lead.Ticket_Medio__c = ticketMedio;
        }
        lead.Tecnologia_Atual__c = tecnologiaAtual;
        lead.Processo_de_Vendas__c = processoDeVendas;
        lead.Nuvens_Utilizadas__c = nuvensUtilizadas;
        if (ticketMedioDasVendasDaEmpresa != null) {
            lead.Ticket_Medio_das_Vendas_da_Empresa__c = ticketMedioDasVendasDaEmpresa;
        }
        lead.Escopo_do_Projeto__c = escopoDoProjeto;
        lead.Tipo_de_Receita__c = tipoDeReceita;
        lead.Tamanho_do_Time_de_Vendas_Atendimento__c = tamanhoDoTimeDeVendasAtendimento;
        
        // Corrigindo a atribuição de utilizaChatbot
        if (utilizaChatbot != null) {
            lead.Utiliza_Chatbot__c = utilizaChatbot.equalsIgnoreCase('Sim') ? 'Sim' : 'Não';
        }
        upsert lead Email; // Use o campo Email como chave externa para upsert

        res.statusCode = 200;
        res.responseBody = Blob.valueOf('Success'); // Converting String to Blob
    }
} */