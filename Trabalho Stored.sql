-- Nomes: Victor Davi Pompeu de Mattos e Gabriela Suzana Passos da Silveira

-- Tabela Areas
CREATE TABLE Areas 
(
  Acod INTEGER PRIMARY KEY,
  Nome VARCHAR(100),
  Descricao TEXT
);

-- Tabela Especialidades
CREATE TABLE Especialidades 
(
  Ecod INTEGER PRIMARY KEY,
  Nome VARCHAR(100),
  CodArea INT REFERENCES Areas(Acod)
);

-- Tabela Planos
CREATE TABLE Planos 
(
  PLcod INTEGER PRIMARY KEY,
  Nome VARCHAR(100),
  Tipo VARCHAR(50)
);

-- Tabela Cidades
CREATE TABLE Cidades 
(
  Ccod INTEGER,
  Nome VARCHAR(100),
  Uf CHAR(2)
);

-- Tabela Pacientes
CREATE TABLE Pacientes 
(
  Pcod INTEGER PRIMARY KEY,
  Nome VARCHAR(100),
  Telefone VARCHAR(20),
  Endereco TEXT,
  DataNasc DATE,
  CodPlano INTEGER REFERENCES Planos(PLcod),
  CodCid INTEGER REFERENCES Cidades(Ccod)
);

-- Tabela Medico
CREATE TABLE Medico 
(
  Crm VARCHAR(20) PRIMARY KEY,
  Nome VARCHAR(100) NOT NULL,
  Telefone VARCHAR(20),
  CodEspecialidade INT REFERENCES Especialidades(Ecod)
);

-- Tabela Consultas
CREATE TABLE Consultas 
(
  CodPaciente INTEGER REFERENCES Pacientes(Pcod),
  CrmMed VARCHAR(20) REFERENCES Medico(Crm),
  Data DATE,
  Hora TIME,
  Valor NUMERIC(10, 2)
);

---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION listar_pacientes()
  RETURNS VOID AS
$$
BEGIN
  -- Declaração da variável para armazenar o nome do paciente
  DECLARE nome_paciente VARCHAR(100);

  -- Cursor para percorrer os registros da tabela Pacientes
  FOR nome_paciente IN SELECT Nome FROM Pacientes LOOP
    -- Exibir o nome do paciente
    RAISE NOTICE 'Nome do paciente: %', nome_paciente;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

CALL listar_pacientes();

---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION listar_pacientes_por_medico(crm_param VARCHAR)
  RETURNS TABLE 
  (
    Pcod INT,
    Nome VARCHAR(100),
    Telefone VARCHAR(20),
    Endereco TEXT,
    DataNasc DATE,
    CodPlano INT,
    CodCid INT
  ) AS
$$
BEGIN
  -- Retorna a lista de pacientes do médico com o CRM fornecido
  RETURN QUERY
    SELECT Pcod, Nome, Telefone, Endereco, DataNasc, CodPlano, CodCid
    FROM Pacientes
    WHERE Pcod IN 
    (
      SELECT CodPaciente
      FROM Consultas
      WHERE CrmMed = crm_param
    );
END;
$$
LANGUAGE plpgsql;

SELECT * FROM listar_pacientes_por_medico('CRM123');

---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inserir_cidade
(
  nome_param VARCHAR,
  uf_param CHAR(2)
) 
RETURNS VOID AS
$$
BEGIN
  -- Inserir os dados na tabela Cidades
  INSERT INTO Cidades (Nome, Uf)
  VALUES (nome_param, uf_param);

  -- Exibir mensagem de sucesso
  RAISE NOTICE 'Dados da cidade inseridos com sucesso.';
END;
$$
LANGUAGE plpgsql;

CALL inserir_cidade('São Paulo', 'SP');

---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION obter_hora_consulta
(
  cod_paciente_param INT,
  crm_medico_param VARCHAR,
  data_consulta_param DATE
) 
RETURNS TIME AS
$$
DECLARE
  hora_consulta TIME;
BEGIN
  -- Obtém a hora da consulta com base nos parâmetros fornecidos
  SELECT Hora INTO hora_consulta
  FROM Consultas
  WHERE CodPaciente = cod_paciente_param
    AND CrmMed = crm_medico_param
    AND Data = data_consulta_param;

  -- Retorna a hora da consulta
  RETURN hora_consulta;
END;
$$
LANGUAGE plpgsql;

SELECT obter_hora_consulta(1, 'CRM123', '2023-06-23');

---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION listar_pacientes_por_cidade
(
  nome_cidade_param VARCHAR
) 
RETURNS TABLE 
(
  Pcod INT,
  Nome VARCHAR(100),
  Telefone VARCHAR(20),
  Endereco TEXT,
  DataNasc DATE,
  CodPlano INT,
  CodCid INT
) AS
$$
BEGIN
  -- Retorna a lista de pacientes que moram na cidade fornecida
  RETURN QUERY
    SELECT Pcod, Nome, Telefone, Endereco, DataNasc, CodPlano, CodCid
    FROM Pacientes
    WHERE CodCid = 
    (
      SELECT Ccod
      FROM Cidades
      WHERE Nome ILIKE nome_cidade_param
    );
END;
$$
LANGUAGE plpgsql;

SELECT * FROM listar_pacientes_por_cidade('São Paulo');

---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION obter_especialidade_medico
(
  crm_param VARCHAR
) 
RETURNS TABLE 
(
  NomeEspecialidade VARCHAR(100)
) AS
$$
BEGIN
  -- Retorna o nome da especialidade do médico com o CRM fornecido
  RETURN QUERY
    SELECT E.Nome
    FROM Medico M
    INNER JOIN Especialidades E ON M.CodEspecialidade = E.Ecod
    WHERE M.Crm = crm_param;
END;
$$
LANGUAGE plpgsql;

SELECT * FROM obter_especialidade_medico('CRM123');

---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION listar_pacientes_por_plano
(
  cod_plano_param INT
) 
RETURNS VOID AS
$$
BEGIN
  -- Declaração da variável para armazenar o nome do paciente
  DECLARE nome_paciente VARCHAR(100);

  -- Cursor para percorrer os registros da tabela Pacientes
  FOR nome_paciente IN SELECT Nome FROM Pacientes WHERE CodPlano = cod_plano_param LOOP
    -- Exibir o nome do paciente
    RAISE NOTICE 'Nome do paciente com o plano de saúde: %', nome_paciente;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

CALL listar_pacientes_por_plano(1);

---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION alterar_nome_area
(
  cod_area_param INT,
  novo_nome_param VARCHAR(100)
) 
RETURNS VOID AS
$$
BEGIN
  -- Atualiza o nome da área com base no código fornecido
  UPDATE Areas
  SET Nome = novo_nome_param
  WHERE Acod = cod_area_param;

  -- Exibir mensagem de sucesso
  RAISE NOTICE 'Nome da área alterado com sucesso.';
END;
$$
LANGUAGE plpgsql;

CALL alterar_nome_area(1, 'Nova Área');

---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION alterar_plano_paciente
(
  cod_paciente_param INT,
  novo_cod_plano_param INT
) 
RETURNS VOID AS
$$
BEGIN
  -- Atualiza o código do plano de saúde do paciente com base no código fornecido
  UPDATE Pacientes
  SET CodPlano = novo_cod_plano_param
  WHERE Pcod = cod_paciente_param;

  -- Exibir mensagem de sucesso
  RAISE NOTICE 'Plano de saúde do paciente alterado com sucesso.';
END;
$$
LANGUAGE plpgsql;

CALL alterar_plano_paciente(1, 2);

---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION aplicar_desconto_consulta
(
  INOUT valor_consulta NUMERIC
) 
RETURNS VOID AS
$$
BEGIN
  -- Aplica o desconto de 50% no valor da consulta
  valor_consulta := valor_consulta * 0.5;

  -- Exibir mensagem de sucesso
  RAISE NOTICE 'Valor da consulta com desconto: %', valor_consulta;
END;
$$
LANGUAGE plpgsql;

DECLARE
  valor NUMERIC := 200.00; -- Valor original da consulta
BEGIN
  CALL aplicar_desconto_consulta(valor);
  -- Aqui você pode utilizar o valor atualizado com o desconto
END;
