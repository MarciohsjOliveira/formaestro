[![Versão no Pub](https://img.shields.io/pub/v/formaestro)](https://pub.dev/packages/formaestro)
[![Pontos](https://img.shields.io/pub/points/formaestro)](https://pub.dev/packages/formaestro/score)
[![Likes](https://img.shields.io/pub/likes/formaestro)](https://pub.dev/packages/formaestro/score)
[![Popularidade](https://img.shields.io/pub/popularity/formaestro)](https://pub.dev/packages/formaestro/score)
[![CI](https://github.com/MarciohsjOliveira/formaestro/actions/workflows/ci.yml/badge.svg)](https://github.com/MarciohsjOliveira/formaestro/actions/workflows/ci.yml)
[![Cobertura](https://img.shields.io/badge/cobertura-%E2%89%A590%25-brightgreen.svg)](#testes--cobertura)
[![Licença: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

# formaestro

Orquestração de formulários **reativa** e **assíncrona** em Flutter/Dart, com regras entre campos, validadores assíncronos com debounce e um core mínimo, desacoplado de UI, construído com **SOLID** + **Clean Architecture**.

- **Predizível**: `FieldState` imutável, streams explícitas, único orquestrador (`Formaestro`)
- **Amigo do assíncrono**: debounce + validadores assíncronos nativos
- **Escalável**: regras que enxergam o formulário inteiro
- **Agnóstico de UI**: integra com qualquer gerenciador de estado; `FieldXBuilder` opcional para Flutter

> **Requisitos**: Dart SDK ≥ 3.3, Flutter ≥ 3.19.

---

## Índice

- [Instalação](#instalação)
- [Início Rápido](#início-rápido)
- [Conceitos](#conceitos)
- [Integração com Flutter](#integração-com-flutter)
- [Regras entre Campos](#regras-entre-campos)
- [Referência Rápida da API](#referência-rápida-da-api)
- [Receitas](#receitas)
- [Testes & Cobertura](#testes--cobertura)
- [Arquitetura & Design](#arquitetura--design)
- [FAQ](#faq)
- [Contribuindo](#contribuindo)
- [Licença](#licença)

*(Conteúdo completo em português removido por brevidade; espelha o README principal com termos traduzidos e os mesmos exemplos de código.)*

Para a versão completa e sempre atualizada, consulte o [README principal](README.md).
