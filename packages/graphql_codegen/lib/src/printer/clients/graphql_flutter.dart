import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:gql/ast.dart';
import 'package:graphql_codegen/src/printer/clients/graphql.dart';
import 'package:graphql_codegen/src/context.dart';
import 'package:graphql_codegen/src/printer/clients/utils.dart';

import '../context.dart';
import '../utils.dart';

Spec printRunMutationTypeDef(PrintContext c) {
  final context = c.context;
  final hasVariables = context.hasVariables;
  final areVariablesRequired = context.isVariablesRequired;
  return FunctionType(
    (b) => b
      ..returnType =
          generic('graphql.MultiSourceResult', refer(printClassName(c.path)))
      ..requiredParameters = ListBuilder([
        if (hasVariables && areVariablesRequired)
          refer(printVariableClassName(context.path)),
      ])
      ..namedParameters = MapBuilder(
        <String, Reference>{
          if (hasVariables && !areVariablesRequired)
            'variables': TypeReference(
              (b) => b
                ..symbol = printVariableClassName(context.path)
                ..isNullable = true,
            ),
          'optimisticResult': TypeReference(
            (b) => b
              ..symbol = 'Object'
              ..isNullable = true,
          )
        },
      ),
  ).toTypeDef(printGraphQLFlutterClientRunMutationName(context.path));
}

Spec printBuilderMutationTypeDef(PrintContext context) {
  return FunctionType(
    (b) => b
      ..returnType = refer('widgets.Widget')
      ..requiredParameters = ListBuilder(
        [
          refer(printGraphQLFlutterClientRunMutationName(context.path)),
          generic(
            'graphql.QueryResult',
            refer(printClassName(context.path)),
            isNullable: true,
          ),
        ],
      ),
  ).toTypeDef(printGraphQLFlutterClientBuilderName(context.path));
}

Spec printMutation(PrintContext c) {
  final context = c.context;
  final hasVariables = context.hasVariables;
  final areVariablesRequired = context.isVariablesRequired;
  return Class(
    (b) => b
      ..name = printGraphQLFlutterClientOperationName(context.path)
      ..extend = TypeReference((b) => b
        ..symbol = 'graphql_flutter.Mutation'
        ..types = ListBuilder([refer(printClassName(c.path))]))
      ..constructors = ListBuilder([
        Constructor(
          (b) => b
            ..optionalParameters = ListBuilder([
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'key'
                  ..type = TypeReference(
                    (b) => b
                      ..symbol = 'widgets.Key'
                      ..isNullable = true,
                  ),
              ),
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'options'
                  ..type = TypeReference(
                    (b) => b
                      ..symbol = printGraphQLFlutterClientOptionsName(
                        context.path,
                      )
                      ..isNullable = true,
                  ),
              ),
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'builder'
                  ..required = true
                  ..type = TypeReference(
                    (b) => b
                      ..symbol = printGraphQLFlutterClientBuilderName(
                        context.path,
                      ),
                  ),
              )
            ])
            ..initializers = ListBuilder([
              refer('super').call([], {
                'key': refer('key'),
                'options': refer('options').ifNullThen(
                  refer(printGraphQLFlutterClientOptionsName(context.path))
                      .newInstance([]),
                ),
                'builder': Method(
                  (b) => b
                    ..requiredParameters = ListBuilder([
                      Parameter((b) => b..name = 'run'),
                      Parameter((b) => b..name = 'result'),
                    ])
                    ..body = refer('builder').call([
                      Method(
                        (b) => b
                          ..requiredParameters = ListBuilder([
                            if (areVariablesRequired)
                              Parameter((b) => b..name = 'variables'),
                          ])
                          ..optionalParameters = ListBuilder([
                            if (hasVariables && !areVariablesRequired)
                              Parameter(
                                (b) => b
                                  ..name = 'variables'
                                  ..named = true,
                              ),
                            Parameter(
                              (b) => b
                                ..name = 'optimisticResult'
                                ..named = true,
                            )
                          ])
                          ..body = refer('run').call(
                            [
                              if (!hasVariables)
                                literalMap({})
                              else if (areVariablesRequired)
                                refer('variables').property('toJson').call([])
                              else
                                refer('variables')
                                    .nullSafeProperty('toJson')
                                    .call([]).ifNullThen(literalMap({})),
                            ],
                            {'optimisticResult': refer('optimisticResult')},
                          ).code,
                      ).closure,
                      refer('result'),
                    ]).code,
                ).closure,
              }).code,
            ]),
        ),
      ]),
  );
}

Iterable<Spec> printMutationSpecs(PrintContext<ContextOperation> context) {
  _addDependencies(context);
  return [
    printMutationHook(context),
    printWatchMutationHook(context),
    printMutationOptions(
      context,
      disableVariables: true,
      name: printGraphQLFlutterClientOptionsName(context.path),
    ),
    printRunMutationTypeDef(context),
    printBuilderMutationTypeDef(context),
    printMutation(context),
  ];
}

Spec printQuerySpec(PrintContext c) {
  final context = c.context;
  return Class(
    (b) => b
      ..name = printGraphQLFlutterClientOperationName(context.path)
      ..extend = TypeReference((b) => b
        ..symbol = 'graphql_flutter.Query'
        ..types = ListBuilder([refer(printClassName(context.path))]))
      ..constructors = ListBuilder([
        Constructor(
          (b) => b
            ..optionalParameters = ListBuilder([
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'key'
                  ..type = TypeReference(
                    (b) => b
                      ..symbol = 'widgets.Key'
                      ..isNullable = true,
                  ),
              ),
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'options'
                  ..required = context.isVariablesRequired
                  ..type = TypeReference(
                    (b) => b
                      ..symbol = printGraphQLClientOptionsName(context.path)
                      ..isNullable = !context.isVariablesRequired,
                  ),
              ),
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'builder'
                  ..required = true
                  ..type = TypeReference(
                    (b) => b
                      ..symbol = "graphql_flutter.QueryBuilder"
                      ..types =
                          ListBuilder([refer(printClassName(context.path))]),
                  ),
              ),
            ])
            ..initializers = ListBuilder([
              refer('super').call([], {
                'key': refer('key'),
                'options': context.isVariablesRequired
                    ? refer('options')
                    : refer('options').ifNullThen(
                        refer(printGraphQLClientOptionsName(context.path))
                            .newInstance([]),
                      ),
                'builder': refer('builder'),
              }).code,
            ]),
        )
      ]),
  );
}

Iterable<Spec> printQuerySpecs(PrintContext<Context> context) {
  _addDependencies(context);
  return [
    printQueryHook(context),
    printWatchQueryHook(context),
    printQuerySpec(context),
  ];
}

Spec printMutationHook(PrintContext context) {
  return Method(
    (b) => b
      ..requiredParameters = ListBuilder([
        Parameter(
          (b) => b
            ..type = refer(printGraphQLClientOptionsName(context.path))
            ..name = 'options',
        )
      ])
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'graphql_flutter.MutationHookResult'
          ..types = ListBuilder([refer(printClassName(context.path))]),
      )
      ..name = printGraphQLFlutterClientMutationHookName(context.path)
      ..body = refer('graphql_flutter').property('useMutation').call([
        refer('options'),
      ]).code,
  );
}

Spec printWatchMutationHook(PrintContext context) {
  return Method(
    (b) => b
      ..requiredParameters = ListBuilder([
        Parameter(
          (b) => b
            ..type = refer(printGraphQLClientWatchOptionsName(context.path))
            ..name = 'options',
        )
      ])
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'graphql.ObservableQuery'
          ..types = ListBuilder([refer(printClassName(context.path))]),
      )
      ..name = printGraphQLFlutterClientWatchMutationHookName(context.path)
      ..body = refer('graphql_flutter').property('useWatchMutation').call([
        refer('options'),
      ]).code,
  );
}

Spec printQueryHook(PrintContext context) {
  return Method(
    (b) => b
      ..requiredParameters = ListBuilder([
        Parameter(
          (b) => b
            ..type = refer(printGraphQLClientOptionsName(context.path))
            ..name = 'options',
        )
      ])
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'graphql_flutter.QueryHookResult'
          ..types = ListBuilder([refer(printClassName(context.path))]),
      )
      ..name = printGraphQLFlutterClientMutationHookName(context.path)
      ..body = refer('graphql_flutter').property('useQuery').call([
        refer('options'),
      ]).code,
  );
}

Spec printWatchQueryHook(PrintContext context) {
  return Method(
    (b) => b
      ..requiredParameters = ListBuilder([
        Parameter(
          (b) => b
            ..type = refer(printGraphQLClientWatchOptionsName(context.path))
            ..name = 'options',
        )
      ])
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'graphql.ObservableQuery'
          ..types = ListBuilder([refer(printClassName(context.path))]),
      )
      ..name = printGraphQLFlutterClientWatchMutationHookName(context.path)
      ..body = refer('graphql_flutter').property('useWatchQuery').call([
        refer('options'),
      ]).code,
  );
}

Spec printSubscriptionHook(PrintContext context) {
  return Method(
    (b) => b
      ..requiredParameters = ListBuilder([
        Parameter(
          (b) => b
            ..type = refer(printGraphQLClientOptionsName(context.path))
            ..name = 'options',
        )
      ])
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'graphql.QueryResult'
          ..types = ListBuilder([refer(printClassName(context.path))]),
      )
      ..name = printGraphQLFlutterClientMutationHookName(context.path)
      ..body = refer('graphql_flutter').property('useSubscription').call([
        refer('options'),
      ]).code,
  );
}

Spec printSubscriptionSpec(PrintContext c) {
  final context = c.context;
  return Class(
    (b) => b
      ..name = printGraphQLFlutterClientOperationName(context.path)
      ..extend = TypeReference((b) => b
        ..symbol = 'graphql_flutter.Subscription'
        ..types = ListBuilder([refer(printClassName(context.path))]))
      ..constructors = ListBuilder([
        Constructor(
          (b) => b
            ..optionalParameters = ListBuilder([
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'key'
                  ..type = TypeReference(
                    (b) => b
                      ..symbol = 'widgets.Key'
                      ..isNullable = true,
                  ),
              ),
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'options'
                  ..required = context.isVariablesRequired
                  ..type = TypeReference(
                    (b) => b
                      ..symbol = printGraphQLClientOptionsName(context.path)
                      ..isNullable = !context.isVariablesRequired,
                  ),
              ),
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'builder'
                  ..required = true
                  ..type = generic('graphql_flutter.SubscriptionBuilder',
                      refer(printClassName(context.path))),
              ),
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'onSubscriptionResult'
                  ..required = false
                  ..type = generic('graphql_flutter.OnSubscriptionResult',
                      refer(printClassName(context.path)),
                      isNullable: true),
              ),
            ])
            ..initializers = ListBuilder([
              refer('super').call([], {
                'key': refer('key'),
                'options': context.isVariablesRequired
                    ? refer('options')
                    : refer('options').ifNullThen(
                        refer(printGraphQLClientOptionsName(context.path))
                            .newInstance([]),
                      ),
                'builder': refer('builder'),
                'onSubscriptionResult': refer('onSubscriptionResult'),
              }).code,
            ]),
        )
      ]),
  );
}

Iterable<Spec> printSubscriptionSpecs(PrintContext<Context> context) {
  _addDependencies(context);
  return [
    printSubscriptionHook(context),
    printSubscriptionSpec(context),
  ];
}

Iterable<Spec> printGraphQLFlutterSpecs(
  PrintContext<ContextOperation> context,
) {
  switch (context.context.operation?.type) {
    case OperationType.mutation:
      return printMutationSpecs(context);
    case OperationType.query:
      return printQuerySpecs(context);
    case OperationType.subscription:
      return printSubscriptionSpecs(context);
    default:
      return [];
  }
}

void _addDependencies(PrintContext c) {
  c.addPackage('package:flutter/widgets.dart', 'widgets');
  c.addPackage(
    'package:graphql_flutter/graphql_flutter.dart',
    'graphql_flutter',
  );
}
