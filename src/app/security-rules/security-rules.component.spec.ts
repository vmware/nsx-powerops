import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SecurityRulesComponent } from './security-rules.component';

describe('SecurityRulesComponent', () => {
  let component: SecurityRulesComponent;
  let fixture: ComponentFixture<SecurityRulesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ SecurityRulesComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(SecurityRulesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
