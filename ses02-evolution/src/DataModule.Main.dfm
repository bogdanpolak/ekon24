object DataModuleMain: TDataModuleMain
  OldCreateOrder = False
  Height = 202
  Width = 317
  object FDConnection1: TFDConnection
    Params.Strings = (
      'ConnectionDef=SQLite_Ekon24')
    LoginPrompt = False
    Left = 32
    Top = 16
  end
  object fdqThresholds: TFDQuery
    Connection = FDConnection1
    SQL.Strings = (
      'SELECT Level, LimitBottom, Discount'
      'FROM Thresholds order by Level, LimitBottom')
    Left = 136
    Top = 16
  end
  object fdqOrderItems: TFDQuery
    Connection = FDConnection1
    SQL.Strings = (
      
        'SELECT Items.ProductId, Items.UnitPrice, Items.DeductedPrice, It' +
        'ems.Units, '
      'Orders.CustomerId, Orders.OrderDate,'
      'Products.Name, Products.AllowDeduction'
      'FROM Items '
      'INNER JOIN Orders ON Orders.OrderId = Items.OrderId'
      'INNER JOIN Products ON Items.ProductId = Products.ProductId'
      'WHERE Orders.OrderId = :OrderId')
    Left = 136
    Top = 72
    ParamData = <
      item
        Name = 'ORDERID'
        DataType = ftString
        ParamType = ptInput
        Value = '2'
      end>
  end
end
