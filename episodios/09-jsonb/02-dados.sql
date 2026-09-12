-- Cinco documentos sintéticos; identificadores sem validade fiscal.
-- Execute depois de 01-tabelas.sql.
INSERT INTO sql_semana_09.documentos
    (documento_id, referencia, metadados)
VALUES
    (1, 'DOC-001', '{
        "origem": "api",
        "situacao": "autorizado",
        "emitente": {"uf": "SP"},
        "protocolo": "PROTO-001",
        "eventos": [{"tipo": "autorizacao", "sequencia": 1}]
    }'),
    (2, 'DOC-002', '{
        "origem": "arquivo",
        "situacao": "cancelado",
        "emitente": {"uf": "RJ"},
        "protocolo": "PROTO-002",
        "eventos": [
            {"tipo": "autorizacao", "sequencia": 1},
            {"tipo": "cancelamento", "sequencia": 2}
        ]
    }'),
    (3, 'DOC-003', '{
        "origem": "api",
        "situacao": "pendente",
        "emitente": {"uf": "MG"},
        "eventos": []
    }'),
    (4, 'DOC-004', '{
        "origem": "api",
        "situacao": "autorizado",
        "emitente": {"uf": "SP"},
        "protocolo": null,
        "eventos": null
    }'),
    (5, 'DOC-005', '{
        "origem": "arquivo",
        "situacao": "pendente"
    }');
